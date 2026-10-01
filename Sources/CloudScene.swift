import SceneKit

/// Builds the 3D condition icon from `cloud.glb`: faceted PBR look, the designer's lights, camera
/// framing, the glTF raindrop animations and a slow clockwise spin. Always a cloud, whatever the weather code.
enum CloudScene {
    /// A point light from `cloud.blend`. The glTF export drops lights, so they are copied here.
    struct StudioLight {
        var name: String
        /// From the cloud centre, in the Blender camera's frame (x right, y up, z toward the camera), model units.
        var offset: SIMD3<Float>
        /// Cycles power in watts.
        var watts: Float

        /// SceneKit lights here don't attenuate, so the inverse-square falloff at the cloud is baked in.
        var intensity: CGFloat { CGFloat(watts / simd_length_squared(offset) * CloudScene.lightScale) }
    }

    /// The three Cycles point lights, as the designer's camera sees them. Lights hang off our camera,
    /// so the spinning cloud is always lit from the same side, as in the reference.
    static let studioLights = [
        StudioLight(name: "key", offset: SIMD3(-6.62, 2.61, 2.04), watts: 2000),  // Light.001: upper left, in front
        StudioLight(name: "rim", offset: SIMD3(2.88, 3.10, -4.71), watts: 2000),  // Light: upper right, behind
        StudioLight(name: "fill", offset: SIMD3(5.27, 0.75, 0.51), watts: 1000),  // Light.002: right
    ]
    /// Watts per square model unit → SceneKit lumens. Tuned against now-page.png.
    static let lightScale: Float = 4
    /// Strength of the generated sky used for soft fill and reflections.
    static let environmentIntensity: CGFloat = 0.5

    static let resource = "3d-icon-reference/cloud.glb"

    /// Cream cloud and cyan drops, picked from now-page.png (the file's "water" is dark blue).
    static let cloudColor = NSColor(srgbRed: 0.88, green: 0.81, blue: 0.64, alpha: 1)
    static let waterColor = NSColor(srgbRed: 0.30, green: 0.78, blue: 0.95, alpha: 1)

    /// Model yaw so the larger bump sits on the left, as in the screenshot.
    static let yaw: Float = .pi / 2 - 0.35
    /// Camera elevation above the horizon (slight top-down view).
    static let pitch: Float = 0.30
    static let fieldOfView: CGFloat = 30
    /// Extra room around the bounding sphere, so falling drops stay inside the vignette.
    static let margin: Float = 1.12
    /// Seconds per full clockwise turn.
    static let spinPeriod: TimeInterval = 12

    static func make(bundle: Bundle = .main) -> SCNScene? {
        guard let url = imageURL(resource, in: bundle), let data = try? Data(contentsOf: url),
              let glb = try? GLBLoader.load(data, flatShading: true) else { return nil }
        return make(from: glb)
    }

    static func make(from glb: GLBScene) -> SCNScene {
        let scene = SCNScene()
        let model = glb.rootNode
        removeDrafts(from: model)
        applyLook(to: model)
        for track in glb.translationTracks {
            model.childNode(withName: track.nodeName, recursively: true)?
                .addAnimation(track.keyframeAnimation(), forKey: "glTF")
        }

        // Centre the visible geometry on the origin, then turn it to show the big bump on the left.
        let (lo, hi) = visibleBounds(of: model)
        model.simdPosition = -(lo + hi) / 2
        let turn = SCNNode()
        turn.simdEulerAngles.y = yaw
        turn.addChildNode(model)
        let idle = SCNNode()
        idle.addChildNode(turn)
        idle.runAction(idleMotion())
        scene.rootNode.addChildNode(idle)

        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.fieldOfView = fieldOfView
        let radius = simd_length(hi - lo) / 2 * margin
        let distance = radius / sin(Float(fieldOfView) * .pi / 360)
        camera.simdPosition = SIMD3(0, sin(pitch), cos(pitch)) * distance
        camera.camera?.zNear = Double(max(distance - radius * 2, 0.01))
        camera.camera?.zFar = Double(distance + radius * 2)
        camera.simdLook(at: .zero)
        scene.rootNode.addChildNode(camera)

        // The camera looks down its -Z axis at the cloud centre, `distance` away.
        for light in studioLights {
            let node = SCNNode()
            node.name = light.name
            node.light = SCNLight()
            node.light?.type = .omni
            node.light?.intensity = light.intensity
            node.simdPosition = light.offset - SIMD3(0, 0, distance)
            camera.addChildNode(node)
        }
        scene.lightingEnvironment.contents = skyImage()
        scene.lightingEnvironment.intensity = environmentIntensity
        return scene
    }

    /// Small equirectangular sky (bright above, dark teal below, like the dial face) that SceneKit
    /// wraps around the scene for image-based fill light. It is never drawn as a background.
    static func skyImage(width: Int = 64, height: Int = 32) -> CGImage? {
        guard let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        let colors = [CGColor(srgbRed: 0.95, green: 0.93, blue: 0.88, alpha: 1),  // zenith
                      CGColor(srgbRed: 0.55, green: 0.58, blue: 0.58, alpha: 1),  // horizon
                      CGColor(srgbRed: 0.04, green: 0.16, blue: 0.20, alpha: 1)]  // nadir
        guard let gradient = CGGradient(colorsSpace: nil, colors: colors as CFArray, locations: [0, 0.5, 1])
        else { return nil }
        // CGContext's origin is bottom-left; the top row of the image is the zenith.
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: height), end: .zero, options: [])
        return ctx.makeImage()
    }

    /// The cloud the raindrops fall from. The file also exports earlier draft clouds (hidden in Blender)
    /// at other positions; they share its material, so they are removed by name.
    static let cloudNode = "Icosphere.007"

    /// Removes top-level cloud-material nodes other than `cloudNode`. Drops and helpers stay.
    static func removeDrafts(from root: SCNNode) {
        for node in root.childNodes where node.name != cloudNode {
            var isCloud = false
            node.enumerateHierarchy { n, _ in
                if let m = n.geometry?.firstMaterial, m.name != "water" { isCloud = true }
            }
            if isCloud { node.removeFromParentNode() }
        }
    }

    private static func applyLook(to root: SCNNode) {
        root.enumerateHierarchy { node, _ in
            for m in node.geometry?.materials ?? [] {
                // Colours only; metalness and roughness come from the file (PBR, see GLBLoader).
                m.diffuse.contents = m.name == "water" ? waterColor : cloudColor
            }
        }
    }

    private static func idleMotion() -> SCNAction {
        // Negative yaw is clockwise when seen from above (SceneKit is right-handed, Y up).
        let spin = SCNAction.rotateBy(x: 0, y: -2 * .pi, z: 0, duration: spinPeriod)
        let bob = SCNAction.sequence([.moveBy(x: 0, y: 0.15, z: 0, duration: 2),
                                      .moveBy(x: 0, y: -0.15, z: 0, duration: 2)])
        bob.timingMode = .easeInEaseOut
        return .group([.repeatForever(spin), .repeatForever(bob)])
    }

    /// Bounds of all nodes with geometry under `root`, in `root`'s local space.
    /// Helper objects have no geometry after loading, so they don't affect the framing.
    static func visibleBounds(of root: SCNNode) -> (SIMD3<Float>, SIMD3<Float>) {
        var lo = SIMD3<Float>(repeating: .infinity)
        var hi = SIMD3<Float>(repeating: -.infinity)
        root.enumerateHierarchy { node, _ in
            guard node.geometry != nil else { return }
            let (a, b) = node.boundingBox
            for corner in 0..<8 {
                let local = SCNVector3(corner & 1 == 0 ? a.x : b.x, corner & 2 == 0 ? a.y : b.y,
                                       corner & 4 == 0 ? a.z : b.z)
                let p = SIMD3<Float>(root.convertPosition(local, from: node))
                lo = simd_min(lo, p)
                hi = simd_max(hi, p)
            }
        }
        return lo.x.isFinite ? (lo, hi) : (.zero, .zero)
    }
}
