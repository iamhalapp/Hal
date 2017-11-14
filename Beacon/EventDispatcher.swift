//
//  EventDispatcher.swift
//  EventDispatcher
//
//  Created by Simon Gladman on 27/07/2015.
//  Copyright © 2015 Simon Gladman. All rights reserved.
//
//  Example usage....
//
//    let stringChangeHandler = EventHandler(function: {
//        (event: Event) in
//        print("hello from string change handler!")
//    })
//
//    let string = DispatchingValue("Hello")
//    string.addEventListener(.change, handler: stringChangeHandler)
//
//    string.string = "Goodbye"
//
//    string.removeEventListener(.change, handler: stringChangeHandler)
//
//    string.string = "---"

import Foundation
import UIKit
import HealthKit

protocol EventDispatcher: class
{
    func addEventListener(type: EventType, handler: EventHandler)
    
    func removeEventListener(type: EventType, handler: EventHandler)
    
    func dispatchEvent(event: Event)
}

extension EventDispatcher
{
    func addEventListener(type: EventType, handler: EventHandler)
    {
        var eventListeners: EventListeners
        
        if let el = objc_getAssociatedObject(self, &EventDispatcherKey.eventDispatcher) as? EventListeners
        {
            eventListeners = el
            
            if let _ = eventListeners.listeners[type]
            {
                eventListeners.listeners[type]?.insert(handler)
            }
            else
            {
                eventListeners.listeners[type] = Set<EventHandler>([handler])
            }
        }
        else
        {
            eventListeners = EventListeners()
            eventListeners.listeners[type] = Set<EventHandler>([handler])
        }
        
        objc_setAssociatedObject(self,
                                 &EventDispatcherKey.eventDispatcher,
                                 eventListeners,
                                 objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
    
    func removeEventListener(type: EventType, handler: EventHandler)
    {
        guard let eventListeners = objc_getAssociatedObject(self, &EventDispatcherKey.eventDispatcher) as? EventListeners,
            let _ = eventListeners.listeners[type]
            else
        {
            // no handler for this object / event type
            return
        }
        
        eventListeners.listeners[type]?.remove(handler)
        
        objc_setAssociatedObject(self,
                                 &EventDispatcherKey.eventDispatcher,
                                 eventListeners,
                                 objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
    
    func dispatchEvent(event: Event)
    {
        guard let eventListeners = objc_getAssociatedObject(self, &EventDispatcherKey.eventDispatcher) as? EventListeners,
            let handlers = eventListeners.listeners[event.type]
            else
        {
            // no handler for this object / event type
            return
        }
        
        for handler in handlers
        {
            handler.function(event)
        }
    }
    
}

// Required for objc_getAssociatedObject and objc_setAssociatedObject
struct EventDispatcherKey
{
    static var eventDispatcher = "eventDispatcher"
}

// Because Swift functions are non-equatable, a wrapper to allow equivalence chenckiong to support remove event listener
struct EventHandler: Hashable
{
    let function: (Event) -> Void
    let id = NSUUID()
    
    var hashValue: Int
    {
        return id.hashValue
    }
}

func == (lhs: EventHandler, rhs: EventHandler) -> Bool
{
    return lhs.id == rhs.id
}

class EventListeners
{
    var listeners: [EventType: Set<EventHandler>] = [:]
}

struct Event
{
    let type: EventType
    let target: EventDispatcher
}

enum EventType: String
{
    case change
    case tap
    case authorized
    case glucoseValues
    case loggedIn
    case selection
    case glucoseIOError
    case authLoginError
    case heartRate
    case refreshToken
    case token
}

// Wrapper to make T dispatch a change event
class DispatchingValue<T>: EventDispatcher
{
    required init(_ value: T)
    {
        self.value = value
    }
    
    var value: T
    {
        didSet
        {
            dispatchEvent(event: Event(type: EventType.change, target: self))
        }
    }
}
