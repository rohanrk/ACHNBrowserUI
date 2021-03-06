//
//  ActiveCrittersViewModel.swift
//  ACHNBrowserUI
//
//  Created by Thomas Ricouard on 01/06/2020.
//  Copyright © 2020 Thomas Ricouard. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import Backend

class ActiveCrittersViewModel: ObservableObject {
    
    enum CritterType: String, CaseIterable {
        case fish = "Fishes"
        case bugs = "Bugs"
        
        func category() -> Backend.Category {
            switch self {
            case .fish: return .fish
            case .bugs: return .bugs
            }
        }
        
        func imagePrefix() -> String {
            switch self {
            case .fish: return "Fish"
            case .bugs: return "Ins"
            }
        }
    }
    
    struct CritterInfo {
        let active: [Item]
        let new: [Item]
        let leaving: [Item]
        let caught: [Item]
        let toCatch: [Item]
    }
    
    @Published var crittersInfo: [CritterType: CritterInfo] = [:]
    
    private let items: Items
    private let collection: UserCollection
    
    private var cancellable: AnyCancellable?
    
    init(filterOutInCollection: Bool = false, items: Items = .shared, collection: UserCollection = .shared) {
        self.items = items
        self.collection = collection
        
        cancellable = Publishers.CombineLatest(items.$categories, collection.$critters)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (items, critters) in
                for type in CritterType.allCases {
                    var active = items[type.category()]?.filterActive() ?? []
                    var new = active.filter{ $0.isNewThisMonth() }
                    var leaving = active.filter{ $0.leavingThisMonth() }
                    let caught = active.filter{ critters.contains($0) }
                    let toCatch = active.filter{ !critters.contains($0) }
                    
                    if filterOutInCollection {
                        new = new.filter{ !critters.contains($0) }
                        leaving = leaving.filter{ !critters.contains($0) }
                        active = active.filter{ !critters.contains($0) }
                    }
                    
                    self?.crittersInfo[type] = CritterInfo(active: active,
                                                           new: new,
                                                           leaving: leaving,
                                                           caught: caught,
                                                           toCatch: toCatch)
                }
        }
    }
}
