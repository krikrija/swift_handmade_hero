//
//  PlatformLayer.swift
//  Handmade Hero Swift Platform
//
//  Created by Karl Kirch on 12/26/14.
//  Copyright (c) 2014 Handmade Hero. All rights reserved.
//

import Foundation

class PlatformLayer {
    
    // uninitialized pointers to our platform layer memory
    var gameMemory = UnsafeMutablePointer<game_memory>.alloc(1)
    var gameInput = UnsafeMutablePointer<game_input>.alloc(1)
    var gameOffscreenBuffer = UnsafeMutablePointer<game_offscreen_buffer>.alloc(1)
    var gameThreadContext: UnsafeMutablePointer<thread_context> = nil
    
    // game code loader
    private var gameCodeLoader = GameCodeLoader()
    
    // input manager
    private let inputManager: InputManager
    
    init(anInputManager: InputManager) {
        inputManager = anInputManager
        
        // initialize all of our memory
        let permanantStorageSize = Helpers.megabytes(64)
        let TransientStorageSize = Helpers.gigabytes(1)
        gameMemory.memory.PermanentStorageSize = permanantStorageSize
        gameMemory.memory.TransientStorageSize = TransientStorageSize
        gameMemory.memory.PermanentStorage = UnsafeMutablePointer<Void>.alloc(Int(permanantStorageSize))
        gameMemory.memory.TransientStorage = UnsafeMutablePointer<Void>.alloc(Int(TransientStorageSize))
        
        
        gameOffscreenBuffer.memory.Width = 960
        gameOffscreenBuffer.memory.Height = 540
        gameOffscreenBuffer.memory.BytesPerPixel = 4
        gameOffscreenBuffer.memory.Pitch = gameOffscreenBuffer.memory.Width * gameOffscreenBuffer.memory.BytesPerPixel
        
        let totalBufferSize = gameOffscreenBuffer.memory.Pitch * gameOffscreenBuffer.memory.Height
        gameOffscreenBuffer.memory.Memory = UnsafeMutablePointer<Void>.alloc(Int(totalBufferSize))

        // load our dylib game code
        gameCodeLoader.loadGameCode()
    }
    
    func platformGameUpdateAndRender() {
        // reload our dylib if it's changed
        gameCodeLoader.reloadGameCodeIfNeeded()
        
        // update input state
        inputManager.updateInputState(gameInput)
        
        // have to do this every frame because of me copying over all of the input state :/
        gameInput.memory.dtForFrame = 1.0 / 60.0
        
        // sanity check
        if (gameCodeLoader.isInitialized) {
            // run function pointer in objc b/c swift can't call function pointers o_0
            shimCallGameUpdateAndRenderFn(gameCodeLoader.gameUpdateAndRenderFn, gameThreadContext, gameMemory, gameInput, gameOffscreenBuffer)
        }
    }
}