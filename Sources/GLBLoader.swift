import Foundation
import QuartzCore
import SceneKit

/// The subset of the glTF 2.0 JSON that `GLBLoader` understands.
struct GLTFDocument: Decodable {
    struct Scene: Decodable { var nodes: [Int]? }
    struct Node: Decodable {
        var name: String?
        var mesh: Int?
        var children: [Int]?
        var translation: [Float]?
        var rotation: [Float]?
        var scale: [Float]?
        var matrix: [Float]?
    }
    struct Mesh: Decodable {
        struct Primitive: Decodable {
            var attributes: [String: Int]
            var indices: Int?
            var material: Int?
            var mode: Int?
        }
        var name: String?
        var primitives: [Primitive]
    }
    struct Accessor: Decodable {
        var bufferView: Int?
        var byteOffset: Int?
        var componentType: Int
        var count: Int
        var type: String
    }
    struct BufferView: Decodable {
        var byteOffset: Int?
        var byteLength: Int
        var byteStride: Int?
    }
    struct Material: Decodable {
        struct PBR: Decodable { var baseColorFactor: [Float]? }
        var name: String?
        var doubleSided: Bool?
        var pbrMetallicRoughness: PBR?
    }
    struct Animation: Decodable {
        struct Channel: Decodable {
            struct Target: Decodable { var node: Int?; var path: String }
            var sampler: Int
            var target: Target
        }
        struct Sampler: Decodable { var input: Int; var output: Int; var interpolation: String? }
        var name: String?
        var channels: [Channel]
        var samplers: [Sampler]
    }

    var scene: Int?
    var scenes: [Scene]?
    var nodes: [Node]?
    var meshes: [Mesh]?
    var accessors: [Accessor]?
    var bufferViews: [BufferView]?
    var materials: [Material]?
    var animations: [Animation]?
}

/// A GLB container split into its JSON document and BIN chunk, with typed accessor reads.
struct GLBFile {
    enum Failure: Error { case notGLB, badChunk, badAccessor(Int) }

    let document: GLTFDocument
    let bin: Data

    init(data: Data) throws {
        let bytes = [UInt8](data)
        func u32(_ at: Int) throws -> Int {
            guard at + 4 <= bytes.count else { throw Failure.badChunk }
            return Int(bytes[at]) | Int(bytes[at + 1]) << 8 | Int(bytes[at + 2]) << 16 | Int(bytes[at + 3]) << 24
        }
        guard try u32(0) == 0x4654_6C67, try u32(4) == 2 else { throw Failure.notGLB } // "glTF", version 2
        var json: Data?
        var bin = Data()
        var offset = 12
        let total = min(try u32(8), bytes.count)
        while offset + 8 <= total {
            let length = try u32(offset)
            let type = try u32(offset + 4)
            let start = offset + 8
            guard start + length <= total else { throw Failure.badChunk }
            let chunk = Data(bytes[start..<start + length])
            switch type {
            case 0x4E4F_534A: json = chunk // "JSON"
            case 0x004E_4942: bin = chunk  // "BIN\0"
            default: break
            }
            offset = start + length
        }
        guard let json else { throw Failure.badChunk }
        document = try JSONDecoder().decode(GLTFDocument.self, from: json)
        self.bin = bin
    }

    private static let components = ["SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4]

    /// Float accessor data (componentType 5126), flattened: `count * components` values.
    func floats(_ index: Int) throws -> [Float] {
        let (a, n, base, stride) = try layout(index, componentSize: 4)
        guard a.componentType == 5126 else { throw Failure.badAccessor(index) }
        return bin.withUnsafeBytes { raw in
            var out = [Float]()
            out.reserveCapacity(a.count * n)
            for i in 0..<a.count {
                for c in 0..<n {
                    out.append(raw.loadUnaligned(fromByteOffset: base + i * stride + c * 4, as: Float.self))
                }
            }
            return out
        }
    }

    /// Index accessor data (unsigned byte, short or int).
    func indices(_ index: Int) throws -> [UInt32] {
        guard let type = document.accessors?[safe: index]?.componentType else { throw Failure.badAccessor(index) }
        let size = [5121: 1, 5123: 2, 5125: 4][type] ?? 0
        guard size > 0 else { throw Failure.badAccessor(index) }
        let (a, _, base, stride) = try layout(index, componentSize: size)
        return bin.withUnsafeBytes { raw in
            (0..<a.count).map { i in
                let at = base + i * stride
                switch size {
                case 1: return UInt32(raw.load(fromByteOffset: at, as: UInt8.self))
                case 2: return UInt32(raw.loadUnaligned(fromByteOffset: at, as: UInt16.self))
                default: return raw.loadUnaligned(fromByteOffset: at, as: UInt32.self)
                }
            }
        }
    }

    private func layout(_ index: Int, componentSize: Int) throws
        -> (GLTFDocument.Accessor, Int, Int, Int) {
        guard let a = document.accessors?[safe: index], let n = Self.components[a.type],
              let view = a.bufferView.flatMap({ document.bufferViews?[safe: $0] }) else {
            throw Failure.badAccessor(index)
        }
        let element = n * componentSize
        let stride = view.byteStride ?? element
        let base = (view.byteOffset ?? 0) + (a.byteOffset ?? 0)
        let end = a.count == 0 ? base : base + (a.count - 1) * stride + element
        guard stride >= element, end <= (view.byteOffset ?? 0) + view.byteLength, end <= bin.count else {
            throw Failure.badAccessor(index)
        }
        return (a, n, base, stride)
    }
}

/// A glTF translation channel, ready to play on the SceneKit node of the same name.
struct GLBTranslationTrack {
    let nodeName: String
    let times: [Float]
    let values: [SIMD3<Float>]

    /// A looping `position` animation. Key times are normalised over the track's own time range.
    func keyframeAnimation() -> CAKeyframeAnimation {
        let start = times.first ?? 0
        let duration = max((times.last ?? 0) - start, 1e-3)
        let anim = CAKeyframeAnimation(keyPath: "position")
        anim.values = values.map { NSValue(scnVector3: SCNVector3($0)) }
        anim.keyTimes = times.map { NSNumber(value: ($0 - start) / duration) }
        anim.duration = CFTimeInterval(duration)
        anim.calculationMode = .linear
        anim.repeatCount = .infinity
        return anim
    }
}

struct GLBScene {
    let rootNode: SCNNode
    let translationTracks: [GLBTranslationTrack]
    /// Number of glTF animations in the file.
    let animationCount: Int
    /// Primitives dropped because they have no material (Blender helper / boolean-cutter objects).
    let skippedPrimitives: Int
}

/// Builds a SceneKit node tree from a GLB. glTF and SceneKit are both Y-up, so no axis conversion.
/// Supports triangle primitives, node TRS/matrix, `baseColorFactor` and translation animations.
enum GLBLoader {
    static func load(_ data: Data, flatShading: Bool = false) throws -> GLBScene {
        let file = try GLBFile(data: data)
        let doc = file.document
        let materials = (doc.materials ?? []).map(makeMaterial)
        var skipped = 0

        // One geometry per primitive: each glTF primitive has its own vertex arrays.
        let geometries: [[SCNGeometry]] = try (doc.meshes ?? []).map { mesh in
            try mesh.primitives.compactMap { p in
                guard let m = p.material, let material = materials[safe: m] else { skipped += 1; return nil }
                guard (p.mode ?? 4) == 4, let pos = p.attributes["POSITION"] else { return nil }
                let positions = try file.floats(pos)
                let idx = try p.indices.map(file.indices) ?? (0..<UInt32(positions.count / 3)).map { $0 }
                let normals = try p.attributes["NORMAL"].map(file.floats)
                let data = flatShading ? flatten(positions: positions, indices: idx)
                    : MeshData(positions: positions, normals: normals ?? [], indices: idx)
                let geometry = SCNGeometry(sources: data.sources(), elements: [data.element()])
                geometry.name = mesh.name
                geometry.materials = [material]
                return geometry
            }
        }

        let nodes = doc.nodes ?? []
        let scnNodes: [SCNNode] = nodes.map { n in
            let node = SCNNode()
            node.name = n.name
            if let m = n.matrix, m.count == 16 {
                // glTF is column-major with column vectors; SCNMatrix4's m41..m43 hold the translation.
                node.transform = SCNMatrix4(m11: CGFloat(m[0]), m12: CGFloat(m[1]), m13: CGFloat(m[2]), m14: CGFloat(m[3]),
                                            m21: CGFloat(m[4]), m22: CGFloat(m[5]), m23: CGFloat(m[6]), m24: CGFloat(m[7]),
                                            m31: CGFloat(m[8]), m32: CGFloat(m[9]), m33: CGFloat(m[10]), m34: CGFloat(m[11]),
                                            m41: CGFloat(m[12]), m42: CGFloat(m[13]), m43: CGFloat(m[14]), m44: CGFloat(m[15]))
            } else {
                if let t = n.translation, t.count == 3 { node.simdPosition = SIMD3(t[0], t[1], t[2]) }
                if let r = n.rotation, r.count == 4 { node.simdOrientation = simd_quatf(ix: r[0], iy: r[1], iz: r[2], r: r[3]) }
                if let s = n.scale, s.count == 3 { node.simdScale = SIMD3(s[0], s[1], s[2]) }
            }
            let parts = n.mesh.flatMap { geometries[safe: $0] } ?? []
            if parts.count == 1 {
                node.geometry = parts[0]
            } else {
                for g in parts { node.addChildNode(SCNNode(geometry: g)) }
            }
            return node
        }
        for (i, n) in nodes.enumerated() {
            for c in n.children ?? [] where scnNodes.indices.contains(c) { scnNodes[i].addChildNode(scnNodes[c]) }
        }

        let root = SCNNode()
        let sceneRoots = doc.scenes?[safe: doc.scene ?? 0]?.nodes
            ?? scnNodes.indices.filter { i in !nodes.contains { $0.children?.contains(i) == true } }
        for i in sceneRoots where scnNodes.indices.contains(i) { root.addChildNode(scnNodes[i]) }

        var tracks: [GLBTranslationTrack] = []
        for anim in doc.animations ?? [] {
            for ch in anim.channels where ch.target.path == "translation" {
                guard let target = ch.target.node, let name = nodes[safe: target]?.name,
                      let sampler = anim.samplers[safe: ch.sampler] else { continue }
                let times = try file.floats(sampler.input)
                let v = try file.floats(sampler.output)
                guard v.count == times.count * 3 else { continue }
                let values = (0..<times.count).map { SIMD3(v[$0 * 3], v[$0 * 3 + 1], v[$0 * 3 + 2]) }
                tracks.append(GLBTranslationTrack(nodeName: name, times: times, values: values))
            }
        }

        return GLBScene(rootNode: root, translationTracks: tracks, animationCount: doc.animations?.count ?? 0,
                        skippedPrimitives: skipped)
    }

    private static func makeMaterial(_ m: GLTFDocument.Material) -> SCNMaterial {
        let material = SCNMaterial()
        material.name = m.name
        let c = m.pbrMetallicRoughness?.baseColorFactor ?? [1, 1, 1, 1]
        // baseColorFactor is linear; tagging it as linear sRGB avoids a second gamma conversion.
        let space = NSColorSpace(cgColorSpace: CGColorSpace(name: CGColorSpace.extendedLinearSRGB)!)!
        let comps = (0..<4).map { CGFloat(c[safe: $0] ?? 1) }
        material.diffuse.contents = NSColor(colorSpace: space, components: comps, count: 4)
        material.isDoubleSided = m.doubleSided ?? false
        return material
    }

    /// De-indexes triangles so each face gets its own vertices and a face normal (faceted look).
    static func flatten(positions: [Float], indices: [UInt32]) -> MeshData {
        var p = [Float]()
        var n = [Float]()
        p.reserveCapacity(indices.count * 3)
        n.reserveCapacity(indices.count * 3)
        let vertex = { (i: UInt32) -> SIMD3<Float> in
            let k = Int(i) * 3
            return SIMD3(positions[k], positions[k + 1], positions[k + 2])
        }
        for t in stride(from: 0, to: indices.count - indices.count % 3, by: 3) {
            let a = vertex(indices[t]), b = vertex(indices[t + 1]), c = vertex(indices[t + 2])
            let cross = simd_cross(b - a, c - a)
            let len = simd_length(cross)
            let normal = len > 0 ? cross / len : SIMD3<Float>(0, 1, 0)
            for v in [a, b, c] {
                p += [v.x, v.y, v.z]
                n += [normal.x, normal.y, normal.z]
            }
        }
        return MeshData(positions: p, normals: n, indices: (0..<UInt32(p.count / 3)).map { $0 })
    }
}

/// Flat vertex arrays for one triangle primitive.
struct MeshData {
    var positions: [Float]
    var normals: [Float]
    var indices: [UInt32]

    func sources() -> [SCNGeometrySource] {
        var out = [Self.source(positions, .vertex)]
        if normals.count == positions.count { out.append(Self.source(normals, .normal)) }
        return out
    }

    func element() -> SCNGeometryElement {
        SCNGeometryElement(data: indices.withUnsafeBufferPointer { Data(buffer: $0) }, primitiveType: .triangles,
                           primitiveCount: indices.count / 3, bytesPerIndex: 4)
    }

    private static func source(_ values: [Float], _ semantic: SCNGeometrySource.Semantic) -> SCNGeometrySource {
        SCNGeometrySource(data: values.withUnsafeBufferPointer { Data(buffer: $0) }, semantic: semantic,
                          vectorCount: values.count / 3, usesFloatComponents: true, componentsPerVector: 3,
                          bytesPerComponent: 4, dataOffset: 0, dataStride: 12)
    }
}

extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
