//
//  WaterPlane.swift
//  LowPolyWater
//
//  Created by Teemu Harju on 27/01/2019.
//  Copyright © 2019 Teemu Harju. All rights reserved.
//

import Foundation

import SceneKit

class WaterPlane {

    static func create(withSideLength sideLength: SCNFloat, segmentCount: UInt16) -> SCNGeometry {

        guard segmentCount * segmentCount < 65535 else {
            fatalError("Too many segments.")
        }

        let triangleSideLength: SCNFloat = sideLength / SCNFloat(segmentCount)

        let offset = sideLength / 2.0
        var vertices: [SCNVector3] = []
        var indices: [UInt16] = []

        indices.reserveCapacity(Int(segmentCount * segmentCount * 3))

        for y: UInt16 in 0...segmentCount {
            for x: UInt16 in 0...segmentCount {
                let vertex = SCNVector3(x: SCNFloat(x) * triangleSideLength - offset,
                                        y: SCNFloat(y) * triangleSideLength - offset,
                                        z: 0.0)
                vertices.append(vertex)
            }
        }

        for y: UInt16 in 0..<segmentCount {
            for x: UInt16 in 0..<segmentCount {
                let idx = y * segmentCount + y + x

                indices.append(idx + 1)
                indices.append(idx + segmentCount + 1)
                indices.append(idx)

                indices.append(idx + segmentCount + 1)
                indices.append(idx + 1)
                indices.append(idx + segmentCount + 2)
            }
        }

        let vertexSource = SCNGeometrySource(vertices: vertices)
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)

        return SCNGeometry(sources: [vertexSource], elements: [element])
    }
}
