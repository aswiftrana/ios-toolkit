import UIKit
import Networking

let endpoint: URLComponents = {
    var components = URLComponents.init()
    components.scheme = "https"
    components.host = "pokeapi.co"
    components.path = "/api/v2/pokemon/ditto/"
    return components
}()

let client = Client.init()
let cancellable = client.get(components: endpoint)
    .sink(receiveCompletion: { error in
        print(error)
    }, receiveValue: { data in
        let json = try! JSONSerialization.jsonObject(with: data, options: [])
        print(json)
    })
