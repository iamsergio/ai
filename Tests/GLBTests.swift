import Foundation
import SceneKit

private let cloudURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("img/3d-icon-reference/cloud.glb")

func runGLBTests() {
    check((try? GLBFile(data: Data("nope".utf8))) == nil, "non-GLB data rejected")
    var truncated = (try? Data(contentsOf: cloudURL)) ?? Data()
    truncated = truncated.prefix(truncated.count / 2)
    check((try? GLBLoader.load(truncated)) == nil, "truncated GLB rejected")

    guard let data = try? Data(contentsOf: cloudURL), let file = try? GLBFile(data: data),
          let glb = try? GLBLoader.load(data) else {
        check(false, "cloud.glb loads")
        return
    }
    let doc = file.document
    check(doc.nodes?.count == 24 && doc.meshes?.count == 18 && doc.materials?.count == 2, "document counts")
    check((try? file.indices(3))?.count == 2880 && (try? file.floats(0))?.count == 1984 * 3, "accessor reads")

    var nodes: [SCNNode] = []
    glb.rootNode.enumerateHierarchy { node, _ in nodes.append(node) }
    check(nodes.count == 25, "24 glTF nodes under the root, got \(nodes.count - 1)")
    let meshNodes = nodes.filter { $0.geometry != nil }
    // Meshes 5–8, 14, 15 and 17 have no material: Blender helper / boolean-cutter objects.
    check(meshNodes.count == 11, "11 visible mesh nodes, got \(meshNodes.count)")
    check(glb.skippedPrimitives == 7, "7 material-less primitives skipped, got \(glb.skippedPrimitives)")
    for helper in ["Icosphere", "Icosphere.001", "Cube", "Icosphere.003", "Cube.001", "Sphere", "Sphere.002"] {
        let node = glb.rootNode.childNode(withName: helper, recursively: true)
        check(node != nil && node?.geometry == nil, "helper \(helper) has no geometry")
    }
    let water = meshNodes.filter { $0.geometry?.firstMaterial?.name == "water" }
    check(water.count == 5, "5 raindrops")
    check(glb.rootNode.childNode(withName: "Empty", recursively: true)?.simdPosition == SIMD3(0, -1, -0.5),
          "node translation")

    check(glb.animationCount == 6 && glb.translationTracks.count == 6, "6 translation animations")
    if let track = glb.translationTracks.first(where: { $0.nodeName == "Empty" }) {
        let anim = track.keyframeAnimation()
        check(anim.keyPath == "position" && anim.repeatCount == .infinity, "looping position animation")
        check(anim.keyTimes?.first == 0 && anim.keyTimes?.last == 1, "key times normalised")
        check(abs(anim.duration - (2.0833 - 0.0417)) < 1e-3, "duration from the time range")
        check(track.values.last == SIMD3(track.values.last!.x, -2, 0.5), "drop falls to its end position")
    } else {
        check(false, "track for Empty")
    }

    // Framing ignores helpers: the cutter at x = -12.5 would push the bounds past -13.
    let (lo, hi) = CloudScene.visibleBounds(of: glb.rootNode)
    check(lo.x > -8 && hi.x < 2 && lo.z > -12 && hi.z < 11, "bounds of visible nodes: \(lo) … \(hi)")

    // Flat shading: one vertex per corner, face normals.
    let quad: [Float] = [0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0]
    let flat = GLBLoader.flatten(positions: quad, indices: [0, 1, 2, 0, 2, 3])
    check(flat.positions.count == 18 && flat.indices == Array(0..<6), "flattened vertices")
    check(stride(from: 0, to: flat.normals.count, by: 3).allSatisfy {
        flat.normals[$0] == 0 && flat.normals[$0 + 1] == 0 && flat.normals[$0 + 2] == 1
    }, "counter-clockwise face normal points +Z")

    let flatGLB = try? GLBLoader.load(data, flatShading: true)
    check(flatGLB?.rootNode.childNode(withName: "Sphere.007", recursively: true)?.geometry?
        .sources(for: .vertex).first?.vectorCount == 2880, "flat-shaded drop has a vertex per index")

    // The scene keeps only the cloud the drops fall from; draft clouds are removed.
    if let flatGLB {
        let scene = CloudScene.make(from: flatGLB)
        var clouds: [String] = [], drops = 0
        scene.rootNode.enumerateHierarchy { node, _ in
            guard let m = node.geometry?.firstMaterial else { return }
            if m.name == "water" { drops += 1 } else { clouds.append(node.name ?? "") }
        }
        check(clouds == [CloudScene.cloudNode] && drops == 5, "one cloud and 5 drops, got \(clouds) and \(drops)")
        check(scene.rootNode.childNode(withName: "Empty.003", recursively: true)?.animationKeys == ["glTF"],
              "raindrop animation attached")
        check(scene.rootNode.childNodes(passingTest: { n, _ in n.camera != nil }).count == 1, "scene has a camera")
    }
}
