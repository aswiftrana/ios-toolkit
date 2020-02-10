//
//  ListView.swift
//  UpcomingEvents
//
//  Created by Asad Rana on 2/9/20.
//  Copyright © 2020 anrana. All rights reserved.
//

import Foundation
import UIKit

protocol LoadableItem {
    var isLoading: Bool { get }
    static var loadingModel: Self { get }
}

struct ListSectionViewModel<Item> {
    let title: String
    let items: [Item]
}

protocol ListDataController {
    associatedtype Item
    func fetchItems(closure: (Result<[ListSectionViewModel<Item>], Error>) -> Void)
}

protocol ListInteractionController {
    associatedtype Item
    func tappedCell(withItem: Item, inList: WeakBox<UITableView>, usingPresenter: WeakBox<UIViewController>)
}

protocol ListCellController {
    associatedtype Item
    func registerCells(for list: WeakBox<UITableView>)
    func cell(for item: Item, indexPath: IndexPath, list: WeakBox<UITableView>) -> UITableViewCell
    func loadingCell(for indexPath: IndexPath, list: WeakBox<UITableView>) -> UITableViewCell
}

struct ListConfiguration {
    let selectable: Bool
    let style: UITableView.Style
    let title: String
    let prefersLargeTitles: Bool
    let showsVerticalScrollIndicator: Bool
    let estimatedRowHeight: CGFloat
}

class ListView<Item: LoadableItem, D: ListDataController, C: ListCellController, I: ListInteractionController>: UITableViewController where D.Item == Item, C.Item == Item, I.Item == Item {
    
    let configuration: ListConfiguration
    let cellController: C
    let dataController: D
    let interactionController: I
    
    var data = [ListSectionViewModel(title: "",
                                    items: .init(repeating: Item.loadingModel,
                                                 count: 20)
        )
    ]
    
    init(configuration: ListConfiguration, cellController: C, dataController: D, interactionController: I) {
        self.configuration = configuration
        self.cellController = cellController
        self.dataController = dataController
        self.interactionController = interactionController
        super.init(style: configuration.style)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureList()
        cellController.registerCells(for: WeakBox(tableView))
        
        dataController.fetchItems { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let data):
                self.data = data
                self.tableView.reloadData()
            case .failure(let error):
                self.present(error: error)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data[section].items.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return data[section].title
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = data[indexPath.section].items[indexPath.row]
        if item.isLoading {
            return cellController.loadingCell(for: indexPath, list: WeakBox(tableView))
        } else {
            return cellController.cell(for: item, indexPath: indexPath, list: WeakBox(tableView))
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = data[indexPath.section].items[indexPath.row]
        interactionController.tappedCell(withItem: item,
                                         inList: WeakBox(tableView),
                                         usingPresenter: WeakBox(self))
    }
    
    private func configureList() {
        title = configuration.title
        navigationController?.navigationBar.prefersLargeTitles = configuration.prefersLargeTitles
        
        tableView.allowsSelection = configuration.selectable
        tableView.showsVerticalScrollIndicator = configuration.showsVerticalScrollIndicator
        tableView.estimatedRowHeight = configuration.estimatedRowHeight
        
        // Defaulted properties
        tableView.rowHeight = UITableView.automaticDimension
    }
    
     private func present(error: Error) {
        let alert = UIAlertController(title: nil,
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"),
                                      style: .default,
                                      handler: nil))
        self.present(alert, animated: true, completion: nil)
    }    
}
