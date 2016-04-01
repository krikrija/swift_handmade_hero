//
//  GameCode.swift
//  Handmade Hero Swift Platform
//
//  Created by Karl Kirch on 12/26/14.
//  Copyright (c) 2014 Handmade Hero. All rights reserved.
//

import Foundation

class GameCodeLoader {

    typealias CUpdateRenderSignature = @convention(c) (UnsafeMutablePointer<thread_context>, UnsafeMutablePointer<game_memory>, UnsafeMutablePointer<game_input>, UnsafeMutablePointer<game_offscreen_buffer>) -> Void
    var gameUpdateAndRenderFn: CUpdateRenderSignature?

    typealias CGetSoundSamplesSignature = @convention(c) (UnsafeMutablePointer<thread_context>, UnsafeMutablePointer<game_memory>, UnsafeMutablePointer<game_sound_output_buffer>) -> Void
    var gameGetSoundSamplesFn: CGetSoundSamplesSignature?

    var isInitialized = false
    let dylibPath: String
    var lastLoadTime = NSDate()
    var dylibRef: UnsafeMutablePointer<Void> = nil
    
    init() {
        let frameworksPath = NSBundle.mainBundle().privateFrameworksPath
        let dylibName = "libHandmade Hero Dylib.dylib"
        dylibPath = frameworksPath! + "/" + dylibName
    }
    
    func reloadGameCodeIfNeeded() -> Bool {
        if (!isInitialized) {
            NSLog("ERROR: Must call loadGameCode before calling reloadGameCodeIfNeeded")
            abort()
        }
        
        var err = NSErrorPointer()
        var attributes: [NSObject: AnyObject]?
        do {
            attributes = try NSFileManager.defaultManager().attributesOfItemAtPath(dylibPath)
        } catch var error as NSError {
            err.memory = error
            attributes = nil
        }
        if (attributes == nil) {
            return false
        }
        var currentLoadTime = attributes![NSFileModificationDate]! as! NSDate
        if (currentLoadTime.compare(lastLoadTime) == NSComparisonResult.OrderedDescending) {
            // ie currentLoadTime > lastLoadTime
            lastLoadTime = currentLoadTime
            unloadGameCode()
            return loadGameCode()
        } else {
            return false
        }
    }
    
    func loadGameCode() -> Bool {
        var didLoadCorrectly = false
        
        dylibRef = dlopen(dylibPath, RTLD_LAZY | RTLD_LOCAL)
        if (dylibRef != nil) {
            gameUpdateAndRenderFn = unsafeBitCast(dlsym(dylibRef, "GameUpdateAndRender"), CUpdateRenderSignature.self)
            gameGetSoundSamplesFn = unsafeBitCast(dlsym(dylibRef, "GameGetSoundSamples"), CGetSoundSamplesSignature.self)
            
            if (gameUpdateAndRenderFn != nil
                && gameGetSoundSamplesFn != nil) {
                didLoadCorrectly = true
            }
        }
        
        if (didLoadCorrectly) {
            NSLog("Successfully loaded game code")
            isInitialized = true
        } else {
            unloadGameCode()
            NSLog("WARNING: Failed to load game code")
        }
        return isInitialized
    }
    
    func unloadGameCode() {
        isInitialized = false
        
        if (dylibRef != nil) {
            dlclose(dylibRef)
            dylibRef = nil
        }
        
        // null out our pointers for good measure...
        gameUpdateAndRenderFn = nil
        gameGetSoundSamplesFn = nil
    }
}
