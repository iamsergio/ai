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
    // PBR factors from the file: both materials are dielectric; the cloud is glossy (roughness 0.042).
    let cloudMaterial = meshNodes.first { $0.geometry?.firstMaterial?.name == "Material.001" }?.geometry?.firstMaterial
    let waterMaterial = water.first?.geometry?.firstMaterial
    check(cloudMaterial?.lightingModel == .physicallyBased && waterMaterial?.lightingModel == .physicallyBased,
          "physically based materials")
    check((cloudMaterial?.metalness.contents as? CGFloat) == 0
          && abs((cloudMaterial?.roughness.contents as? CGFloat ?? 1) - 0.0424) < 1e-3, "cloud metalness and roughness")
    check((waterMaterial?.roughness.contents as? CGFloat).map { abs($0 - 0.5) < 1e-6 } == true, "water roughness")
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
        let cameras = scene.rootNode.childNodes(passingTest: { n, _ in n.camera != nil })
        check(cameras.count == 1, "scene has a camera")

        // The designer's three point lights ride on the camera; key upper-left, rim behind, fill right.
        let lights = cameras.first?.childNodes.filter { $0.light?.type == .omni } ?? []
        check(lights.map(\.name) == ["key", "rim", "fill"], "three studio lights on the camera, got \(lights.map(\.name))")
        if let camera = cameras.first, lights.count == 3 {
            let toCloud = camera.simdConvertPosition(.zero, from: scene.rootNode)
            let rel = lights.map { $0.simdPosition - toCloud }
            check(rel[0].x < 0 && rel[0].y > 0 && rel[0].z > 0, "key light upper left, in front of the cloud")
            check(rel[1].z < 0 && rel[2].x > 0, "rim light behind, fill light on the right")
            check(lights.allSatisfy { $0.light!.intensity > 0 }, "lights are on")
        }
        check(scene.lightingEnvironment.contents != nil, "environment light set")
    }
    check(CloudScene.skyImage().map { $0.width == 64 && $0.height == 32 } == true, "sky image size")
}
