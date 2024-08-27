//  DetailView.swift
//  TicketMasterApplication
//
//  Created by Neranjhana  on 30/04/23.
//

import SwiftUI
import MapKit
import SwiftUIX
import SimpleToast


extension Color {
    static let mustard = Color(red: 212/255, green: 175/255, blue: 55/255)
}

struct EventDetails: Identifiable {
    let id = UUID()
    var name: String = ""
    var date: String = ""
    var artist: String = ""
    var venue: String = ""
    var genre: String = ""
    var minPrice: String = ""
    var maxPrice: String = ""
    var priceend: String = ""
    var ticketstatus: String = ""
    var statusCode: String = ""
    var imageURL: String = ""
    var ticketLink: String = ""
    var attractions: [[String: Any]] = []
   

}
class EventDetailsData: ObservableObject {
    @Published var events: [EventDetails] = []
}


struct FavoritesDetails: Identifiable, Encodable, Decodable {
    let id = UUID()
    var date: String = ""
    var name: String = ""
    var venue: String = ""
    var genre: String = ""
   

}



struct VenueDetails: Identifiable {
    let id = UUID()
    var name: String = ""
    var address: String = ""
    var phoneNumber: String = ""
    var openHours: String = ""
    var generalRule: String = ""
    var childRule: String = ""
    var mapLink: String = ""
    var latitude: String = ""
    var longitude: String = ""
}
class VenueDetailsData: ObservableObject {
    @Published var events: [VenueDetails] = []
}


struct ArtistDetails: Identifiable {
    let id = UUID()
    var artistname: String = ""
    var popularity: Int = 0
    var followers: Int = 0
    var artistimage: String = ""
    var spotifylink: String = ""
    var albumlink1: String = ""
    var albumlink2: String = ""
    var albumlink3: String = ""

}

class ArtistDetailsData: ObservableObject {
    @Published var artists: [ArtistDetails] = []
}


func handleLogin(for attractions: [[String: Any]], completion: @escaping ([ArtistDetails]) -> Void) {
    print("inside handlelogin function")
    Task {
        do{
            print("inside handlelogin function1")
            var artistsDetailsArray = [ArtistDetails]()
           
            let url = URL(string: "https://server-dot-reactticketmasterapplication.ue.r.appspot.com/spotifylogin")!
            print("inside handlelogin function2")
            let response = try await URLSession.shared.data(from: url)
            print("inside handlelogin function3")
            let loginData = String(decoding: response.0, as: UTF8.self)
            print("login data is", loginData)
           
           
            for attraction in attractions where attraction["classifications"] != nil {
               
                var artistDetail = ArtistDetails()
                if let classifications = attraction["classifications"] as? [[String: Any]],
                   let segment = classifications.first?["segment"] as? [String: Any],
                   let segmentName = segment["name"] as? String,
                   segmentName == "Music"
                {
                    if let name = attraction["name"] as? String {
                        let artistName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                        let searchURL = URL(string: "https://server-dot-reactticketmasterapplication.ue.r.appspot.com/spotifysearch?access_token=\(loginData)&q=\(artistName)")!
                        let searchResponse = try await URLSession.shared.data(from: searchURL)
                        let spotifyData = try JSONSerialization.jsonObject(with: searchResponse.0, options: []) as! [String: Any]
                        print("attraction is", name)
                        print("spotify data", spotifyData)
                       
                       
                        if let artists = spotifyData["artists"] as? [String: Any],
                           let items = artists["items"] as? [[String: Any]],
                           let item = items.first,
                           let name = item["name"] as? String,
                           let popularity = item["popularity"] as? Int,
                           let artistid = item["id"] as? String,
                           let followers = item["followers"] as? [String: Any],
                           let totalFollowers = followers["total"] as? Int,
                           let externalUrls = item["external_urls"] as? [String: Any],
                           let spotifyUrl = externalUrls["spotify"] as? String, let images = item["images"] as?[[String: Any]], let image = images.first, let artisturl = image["url"] as? String {
                            print("Name: \(name)")
                            print("Popularity: \(popularity)")
                            print("Total Followers: \(totalFollowers)")
                            print("Spotify URL: \(spotifyUrl)")
                            print("Artist ID is", artistid)
                            print("Artist URL is", artisturl)
                            artistDetail.artistname = name
                            artistDetail.popularity = popularity
                            artistDetail.followers = totalFollowers
                            artistDetail.spotifylink = spotifyUrl
                            artistDetail.artistimage = artisturl
                           
                           
                            //Make request for album details
                            let albumSearchURL = URL(string: "https://server-dot-reactticketmasterapplication.ue.r.appspot.com/spotifyalbumsearch?access_token=\(loginData)&q=\(artistid)")!
                            let albumSearchResponse = try await URLSession.shared.data(from: albumSearchURL)
                            let albumSearchData = try JSONSerialization.jsonObject(with: albumSearchResponse.0, options: []) as! [String: Any]
                           
                            print("ALBUM SEARCH DATA IS", albumSearchData)
                            let jsonData = try JSONSerialization.data(withJSONObject: albumSearchData, options: .prettyPrinted)
                            if let jsonString = String(data: jsonData, encoding: .utf8), let jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                               let items = jsonDict["items"] as? [[String: Any]],
                               items.count >= 3 {
                                if let item1 = items[0]["images"] as? [[String: Any]],
                                   let item2 = items[1]["images"] as? [[String: Any]],
                                   let item3 = items[2]["images"] as? [[String: Any]],
                                   let item1URL = item1.first?["url"] as? String,
                                   let item2URL = item2.first?["url"] as? String,
                                   let item3URL = item3.first?["url"] as? String {
                                    // Do something with item1URL, item2URL, and item3URL
                                    print("Item 1 URL: \(item1URL)")
                                    print("Item 2 URL: \(item2URL)")
                                    print("Item 3 URL: \(item3URL)")
                                    artistDetail.albumlink1 = item1URL
                                    artistDetail.albumlink2 = item2URL
                                    artistDetail.albumlink3 = item3URL
                                }
                            }
                        }
                    }
                    artistsDetailsArray.append(artistDetail)
                }
            }
            print("in the end artist detail array is", artistsDetailsArray)
            completion(artistsDetailsArray)
        } catch {
            print("Error fetching artist details: \(error.localizedDescription)")
        }
    }
}


func fetchEventDetails(for eventId: String, completion: @escaping (EventDetails) -> Void) {
    Task {
        do {
            print("event id is", eventId)
            var eventDetailsArray = EventDetails()
            let url = URL(string: "https://server-dot-reactticketmasterapplication.ue.r.appspot.com/eventdetails?eventId=\(eventId)")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            let (data, _) = try await URLSession.shared.data(for: request)
            if let stringData = String(data: data, encoding: .utf8) {
                print("event details data is", stringData)
                if let jsonData = stringData.data(using: .utf8) {
                    do {
                        if let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:Any] {
                           
                            if let name = jsonObject["name"] as? String{
                               
                                print("JSONobject name is", name)
                                eventDetailsArray.name = name
                               
                            }
                           
                            if let dates = jsonObject["dates"] as? [String: Any], let start = dates["start"] as? [String: Any] {
                                if let localDate = start["localDate"] as? String {
                                    print("Event start date: \(localDate)")
                                    eventDetailsArray.date = localDate
                                }
                               
                            }
                           
                            if let embedded = jsonObject["_embedded"] as? [String: Any], let venues = embedded["venues"] as? [[String: Any]], let venueName = venues.first?["name"] as? String {
                                print("Venue name: \(venueName)")
                                eventDetailsArray.venue = venueName
                            }

                            // Artist/Team Name
                            if let embedded = jsonObject["_embedded"] as? [String: Any], let attractions = embedded["attractions"] as? [[String: Any]], let artistName = attractions.first?["name"] as? String {
                                print("Artist/Team name: \(artistName)")
                                eventDetailsArray.artist = artistName
                            }
                           
                            // Genre Name
                            if let classifications = jsonObject["classifications"] as? [[String: Any]], let genre = classifications.first?["genre"] as? [String: Any], let genreName = genre["name"] as? String, genreName != "Undefined" {
                                print("Genre name: \(genreName)")
                                eventDetailsArray.genre = genreName
                            }
                           
                            // Price Ranges
                            if let priceRanges = jsonObject["priceRanges"] as? [[String: Any]], let minPrice = priceRanges.first?["min"] as? Double, let maxPrice = priceRanges.first?["max"] as? Double {
                                print("Price Ranges: \(minPrice) - \(maxPrice)")
                                eventDetailsArray.minPrice = String(minPrice)
                                eventDetailsArray.maxPrice = String(maxPrice)
                            }
                       
                            //Status code
                            if let dates = jsonObject["dates"] as? [String: Any], let status = dates["status"] as? [String: Any], let statusCode = status["code"] as? String {
                                print("Status Code: \(statusCode)")
                                eventDetailsArray.statusCode = statusCode
                            }
                           
                            //Image seatmap
                            if let seatmap = jsonObject["seatmap"] as? [String: Any], let staticUrl = seatmap["staticUrl"] as? String {
                                eventDetailsArray.imageURL = staticUrl
                                print("imageURL: \(staticUrl)")
                            }
                           
                            //Buy ticket link
                            if let eventUrlString = jsonObject["url"] as? String {
                                eventDetailsArray.ticketLink = eventUrlString
                                print("ticketlink: \(eventUrlString)")
                            }
                           
                            //Attractions
                           
                            if let embedded = jsonObject["_embedded"] as? [String: Any] {
                                if let attractions = embedded["attractions"] as? [[String: Any]] {
                                    print("Attractions: \(attractions)")
                                    print("Attractions over")
                                    eventDetailsArray.attractions = attractions
                                }
                            }
                           
                            }
                           
                           
                        }
                    }
                }
            
            completion(eventDetailsArray)
           
        } catch {
            print("Error fetching event details: \(error.localizedDescription)")
        }
    }
}




func fetchVenueDetails(for venueId: String, completion: @escaping (VenueDetails?) -> Void) {
    Task {
        do {

            print("venue id is", venueId)
            var venueDetails = VenueDetails() // Create a single instance of VenueDetails
            let encodedVenueId = venueId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            print("Encoded venue ID is", encodedVenueId)
            let url = URL(string: "https://server-dot-reactticketmasterapplication.ue.r.appspot.com/venuedetails?keyword=\(encodedVenueId)")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            let (data, _) = try await URLSession.shared.data(for: request)
            if let stringData = String(data: data, encoding: .utf8) {
                print("data received from venues is", stringData)
                if let jsonData = stringData.data(using: .utf8) {
                    do {
                        if let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:Any] {
                           
                                if let embedded = jsonObject["_embedded"] as? [String: Any], let venues = embedded["venues"] as? [[String: Any]], let venueName = venues.first?["name"] as? String {
                                    print("Venue name: \(venueName)")
                                    venueDetails.name = venueName
                                }
                           
                            if let embedded = jsonObject["_embedded"] as? [String: Any], let venues = embedded["venues"] as? [[String: Any]], let venue = venues.first, let venueaddress = venue["address"] as? [String: Any], let venueaddressline1 = venueaddress["line1"] as? String {
                                print("Venue address line1: \(venueaddressline1)")
                                venueDetails.address = venueaddressline1
                            }
                           
                           
                            if let embedded = jsonObject["_embedded"] as? [String: Any], let venues = embedded["venues"] as? [[String: Any]], let venue = venues.first, let boxofficeinfo = venue["boxOfficeInfo"] as? [String: Any]{
                               
                                if let phonenumber = boxofficeinfo["phoneNumberDetail"] as? String
                                {
                                   
                                    print("Phone number: \(phonenumber)")
                                    venueDetails.phoneNumber = phonenumber
                                }
                               
                               
                                if let openhoursdetail = boxofficeinfo["openHoursDetail"] as? String
                                {
                                   
                                    print("Open hours detail: \(openhoursdetail)")
                                    venueDetails.openHours = openhoursdetail
                                }
                               
                            }
                           
                            if let embedded = jsonObject["_embedded"] as? [String: Any], let venues = embedded["venues"] as? [[String: Any]], let venue = venues.first, let boxofficeinfo = venue["generalInfo"] as? [String: Any]{
                               
                                if let generalrule = boxofficeinfo["generalRule"] as? String
                                {
                                   
                                    print("General rule: \(generalrule)")
                                    venueDetails.generalRule = generalrule
                                }
                               
                               
                                if let childrule = boxofficeinfo["childRule"] as? String
                                {
                                   
                                    print("Child Rule: \(childrule)")
                                    venueDetails.childRule = childrule
                                }
                               
                                if let embedded = jsonObject["_embedded"] as? [String: Any], let venues = embedded["venues"] as? [[String: Any]], let venue = venues.first, let location = venue["location"] as? [String: Any]{
                                    print("Loc details is", location)
                                    if let longitude = location["longitude"] as? String {
                                        print("Longitude: \(longitude)")
                                        venueDetails.longitude = longitude
                                    }

                                    if let latitude = location["latitude"] as? String {
                                        print("Latitude: \(latitude)")
                                        venueDetails.latitude = latitude
                                    }
                                   
                                   
                                }
                                
                                
                            }
                           
                        }
                    }
                }
            }
            
            print("latitude is", venueDetails.latitude)
            print("longitude is", venueDetails.longitude)
            print("venue name is", venueDetails.name)
           
            completion(venueDetails) // Return the single instance of VenueDetails
           
        } catch {
            print("Error fetching venue details: \(error.localizedDescription)")
            completion(nil) // Call the completion handler with nil to indicate that an error occurred
        }
    }
}


struct DetailView: View {
    var eventId: String
    var venueId: String
    
   
    enum Tab {
        case events
        case artistTeam
        case venue
    }
   
    @State private var selectedTab: Tab = .events
    @State private var eventDetails: EventDetails?
    @State private var venueDetails: VenueDetails?
    @State private var artistDetails: [ArtistDetails]?
   
    var body: some View {
        Group {
            if let eventDetails = eventDetails {
                NavigationView {
                    VStack {
                        Text(eventDetails.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.top, -40)
                       
                        TabView(selection: $selectedTab) {
                            EventsListView(eventDetails: eventDetails)
                                .tabItem {
                                    Image(systemName: "text.bubble")
                                    Text("Events")
                                }
                                .tag(Tab.events)
                           
                            if let artistDetailsArray = artistDetails {
                                if artistDetailsArray.isEmpty {
                                        VStack(alignment: .center) {
                                            Spacer()
                                            Text("No music related artist details to show")
                                                .font(.title)
                                                .foregroundColor(.black)
                                                .bold()
                                                .padding(.horizontal, 10)
                                            Spacer()
                                        }
                                        .tabItem {
                                            Image(systemName: "guitars")
                                            Text("Artist/Team")
                                        }
                                        .tag(Tab.artistTeam)
                                    } else {
                                        ArtistsListView(artistDetails: artistDetailsArray)
                                            .tabItem {
                                                Image(systemName: "guitars")
                                                Text("Artist/Team")
                                            }
                                            .tag(Tab.artistTeam)
                                    }
                            } else {
                                VStack {
                                    ProgressView()
                                    Text("Please wait...")
                                        .foregroundColor(.black)
                                        .padding(.top, 8)
                                }
                                .tabItem {
                                    Image(systemName: "guitars")
                                    Text("Artist/Team")
                                }
                                .tag(Tab.artistTeam)
                                .onAppear {
                                    handleLogin(for: eventDetails.attractions) { artistDetails in
                                        DispatchQueue.main.async {
                                            self.artistDetails = artistDetails
                                        }
                                    }
                                }
                            }
                           
                            if let venueDetails = venueDetails {
                                VenuesListView(venueDetails: venueDetails)
                                    .tabItem {
                                        Image(systemName: "location")
                                        Text("Venue")
                                    }
                                    .tag(Tab.venue)
                            } else {
                                VStack {
                                    ProgressView()
                                    Text("Please wait...")
                                        .foregroundColor(.black)
                                        .padding(.top, 8)
                                }
                                .tabItem {
                                    Image(systemName: "arrow.right")
                                    Text("Venue")
                                }
                                .tag(Tab.venue)
                                .onAppear {
                                    fetchVenueDetails(for: venueId) { venueDetails in
                                        DispatchQueue.main.async {
                                            self.venueDetails = venueDetails
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .accentColor(.blue)
                    .navigationBarTitleDisplayMode(.inline)
                }
            } else {
                VStack {
                    ProgressView()
                    Text("Please wait...")
                        .foregroundColor(.black)
                        .padding(.top, 8)
                }
                .onAppear {
                    fetchEventDetails(for: eventId) { eventDetails in
                        DispatchQueue.main.async {
                            self.eventDetails = eventDetails
                            fetchVenueDetails(for: venueId) { venueDetails in
                                DispatchQueue.main.async {
                                    self.venueDetails = venueDetails
                                }
                            }
                            handleLogin(for: eventDetails.attractions) { artistDetails in
                                DispatchQueue.main.async {
                                    self.artistDetails = artistDetails
                                }
                            }
                       }
                    }
                }
            }
        }
    }
}


struct EventsListView: View {
    // Get the standard UserDefaults object

    var eventDetails: EventDetails
    @AppStorage("eventDetails") var storedEventDetails: Data?
    @State private var isFavorite = false
    @State private var showToastSaved: Bool = false
    @State private var showToastRemoved: Bool = false
    @State private var toastText = ""
    @State var showToast: Bool = false
    @State var showToastDeleted: Bool = false
    

    private let toastOptions = SimpleToastOptions(
        hideAfter: 2
        
    )
   
    var body: some View {
        VStack() {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                           Text("Date")
                                .font(.title3)
                               .fontWeight(.bold)
                               .foregroundColor(.black)
                           Text(eventDetails.date)
                               .foregroundColor(.gray)
                               .font(.headline)
                           Text("Venue")
                                .font(.title3)
                               .fontWeight(.bold)
                               .foregroundColor(.black)
                           Text(eventDetails.venue)
                               .foregroundColor(.gray)
                               .font(.headline)
                           Text("Price Range")
                                .font(.title3)
                               .fontWeight(.bold)
                               .foregroundColor(.black)
                           Text("\(eventDetails.minPrice) - \(eventDetails.maxPrice) \(eventDetails.priceend)")
                               .foregroundColor(.gray)
                               .font(.headline)
                       }
               
                Spacer()
               
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Artist")
                        .fontWeight(.bold)
                        .font(.title3)
                        .foregroundColor(.black)
                    Text(eventDetails.artist)
                        .foregroundColor(.gray)
                        .font(.headline)
                    Text("Genre")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Text(eventDetails.genre)
                        .foregroundColor(.gray)
                        .font(.headline)
                    Text("Ticket Status")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Text(eventDetails.statusCode)
                        .font(.subheadline)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(getBackgroundColor())
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .frame(width: 100)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.bottom, 16)
            
            GeometryReader { geometry in
                
                VStack {
                    Button(action: {
                        if let existingData = storedEventDetails {
                            do {
                                let decodedData = try JSONDecoder().decode([FavoritesDetails].self, from: existingData)
                                if decodedData.isEmpty{
                                    storedEventDetails = nil
                                }
                            } catch {
                                print("Error decoding existing data: \(error)")
                            }
                        }
                        
                        
                        if isFavorite {
                            // handle remove event from favorites action here
                            if var existingData = storedEventDetails {
                                // Check if existingData is in the correct format
                                if !JSONSerialization.isValidJSONObject(existingData) {
                                    // Convert existingData to the correct format
                                    existingData = Data("[\(String(data: existingData, encoding: .utf8)!)]".utf8)
                                }
                                
                                do {
                                    if isFavorite {
                                        // Remove event from favorites
                                        showToastDeleted = true
                                        if let storedData = storedEventDetails {
                                            if var decodedData = try? JSONDecoder().decode([FavoritesDetails].self, from: storedData) {
                                                if decodedData.count > 0 {
                                                    
                                                    print("Event name inside deletion", eventDetails.name)
                                                    
                                                    decodedData.removeAll { item in
                                                        if item.name == eventDetails.name {
                                                            print(item.name)
                                                            print("Item name is", eventDetails.name)
                                                            print("MATCHING, SHOULD REMOVE")
                                                            storedEventDetails = nil
                                                            return true
                                                        } else {
                                                            print("Item name is", eventDetails.name)
                                                            return false
                                                        }
                                                    }
                                                    
                                                    
                                                    
                                                }
                                            }
                                        }
                                              
                                        
                                    } else {
                                        var decodedExistingData = try JSONDecoder().decode([FavoritesDetails].self, from: existingData)
                                        // Add event to favorites
                                        let favdata = FavoritesDetails(date: eventDetails.date,name: eventDetails.name, venue: eventDetails.venue, genre: eventDetails.genre)
                                        decodedExistingData.append(favdata)
                                        let encoder = JSONEncoder()
                                        let newData = try encoder.encode(decodedExistingData)
                                        storedEventDetails = newData
                                        showToast = true
                                    }
                                    isFavorite.toggle()
                                    print("isFavorite is now \(isFavorite)")
                                } catch {
                                    print("Error decoding existing data: \(error)")
                                }
                            } else {
                                // Add event to favorites
                                let favdata = FavoritesDetails(date: eventDetails.date,name: eventDetails.name, venue: eventDetails.venue, genre: eventDetails.genre)
                                print("ADDING EVENT")
                                do {
                                    showToast = true
                                    let encoder = JSONEncoder()
                                    let newEventDetailsData = try encoder.encode([favdata])
                                    storedEventDetails = newEventDetailsData
                                    isFavorite.toggle()
                                    print("isFavorite is now \(isFavorite)")
                                } catch {
                                    print("Error encoding event details: \(error)")
                                }
                            }
                        } else {
                            // Handle add event to favorites action here
                            if var existingData = storedEventDetails {
                                // Check if existingData is in the correct format
                                if !JSONSerialization.isValidJSONObject(existingData) {
                                    // Convert existingData to the correct format
                                    existingData = Data("[\(String(data: existingData, encoding: .utf8)!)]".utf8)
                                }
                                
                                do {
                                    var decodedExistingData = try JSONDecoder().decode([FavoritesDetails].self, from: existingData)
                                    // Add event to favorites
                                    let favdata = FavoritesDetails(date: eventDetails.date,name: eventDetails.name, venue: eventDetails.venue, genre: eventDetails.genre)
                                    decodedExistingData.append(favdata)
                                    
                                    let encoder = JSONEncoder()
                                    let newData = try encoder.encode(decodedExistingData)
                                    storedEventDetails = newData
                                    isFavorite.toggle()
                                    showToast = true
                                    print("isFavorite is now \(isFavorite)")
                                } catch {
                                    print("Error decoding existing data: \(error)")
                                }
                            } else {
                                // Add event to favorites
                                let favdata = FavoritesDetails(date: eventDetails.date,name: eventDetails.name, venue: eventDetails.venue, genre: eventDetails.genre)
                                print("ADDING EVENT")
                                do {
                                    showToast = true
                                    let encoder = JSONEncoder()
                                    let newEventDetailsData = try encoder.encode([favdata])
                                    storedEventDetails = newEventDetailsData
                                    isFavorite.toggle()
                                    print("isFavorite is now \(isFavorite)")
                                } catch {
                                    print("Error encoding event details: \(error)")
                                }
                            }
                        }
                    }) {
                        Text(isFavorite ? "Remove from favorites" : "Save event")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isFavorite ? .white : .white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .cornerRadius(14)
                    }
                    .background(isFavorite ? Color.red : Color.blue)
                    .cornerRadius(8)
                    
                    
                    
                    AsyncImage(url: URL(string: eventDetails.imageURL)) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    
                }.simpleToast(isShowing: $showToast, options: toastOptions) {
                    HStack(alignment: .bottom) {
                        Text("Added to favorites")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.8))
                    .foregroundColor(Color.white)
                    .cornerRadius(10)
                    .frame(width: geometry.size.width, height: 550)
                }
                .simpleToast(isShowing: $showToastDeleted, options: toastOptions) {
                    HStack(alignment: .bottom) {
                        Text("Remove favorite")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.8))
                    .foregroundColor(Color.white)
                    .cornerRadius(10)
                    .frame(width: geometry.size.width, height: 550)
                }
            }
           
            HStack {
                Text("Buy Ticket At:")
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Button(action: {
                    guard let url = URL(string: eventDetails.ticketLink) else { return }
                    UIApplication.shared.open(url)
                }) {
                    Text("Ticketmaster")
                        .foregroundColor(.blue)
                }
            }
            Spacer().frame(height: 15)
            HStack {
                Text("Share on:")
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                if let ticketLinkURL = URL(string: eventDetails.ticketLink) {
                    let facebookURLString = "https://www.facebook.com/sharer/sharer.php?u=\(ticketLinkURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)&src=sdkpreparse"
                    if let facebookURL = URL(string: facebookURLString) {
                        Link(destination: facebookURL, label: {
                            Image("f_logo_RGB-Blue_144")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                        })
                    }
                }
                Link(destination: URL(string: "https://twitter.com/share?url=\(eventDetails.ticketLink)")!) {
                    Image("Twitter social icons - circle - blue")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                }
            }
           
            Spacer()
           
           
        }
        .foregroundColor(.gray)
        .padding()
    }
   
    private func getBackgroundColor() -> Color {
        switch eventDetails.statusCode {
        case "onsale":
            return Color.green
        case "cancelled":
            return Color.black
        case "postponed", "rescheduled":
            return Color.orange
        default:
            return Color.gray
        }
    }

}


struct VenuesListView: View {
   
    var venueDetails: VenueDetails
    @State private var showingMap = false
    @State private var offset = CGSize.zero
    @State private var dragging = false
   
    var body: some View {
        VStack {
           
            Text("Name")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.black)
            Text(venueDetails.name)
                .foregroundColor(.gray)
                .font(.headline)
            Text("Address")
                 .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.black)
            Text(venueDetails.address)
                .foregroundColor(.gray)
                .font(.headline)
            
            if !venueDetails.phoneNumber.isEmpty{
                Text("Phone Number")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Text(venueDetails.phoneNumber)
                    .foregroundColor(.gray)
                    .font(.headline)
            }
            VStack {
                
                
                if !venueDetails.openHours.isEmpty{
                    Text("Open Hours")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    ScrollView {
                        Text(venueDetails.openHours)
                            .foregroundColor(.gray)
                            .font(.headline)
                            .frame(maxHeight: venueDetails.openHours.split(separator: "\n").count > 3 ? 100 : .infinity)
                    }
                }
                
                if !venueDetails.generalRule.isEmpty{
                    
                    Text("General Rule")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    ScrollView {
                        Text(venueDetails.generalRule)
                            .foregroundColor(.gray)
                            .font(.headline)
                            .frame(maxHeight: venueDetails.generalRule.split(separator: "\n").count > 3 ? 100 : .infinity)
                    }
                }
                if !venueDetails.childRule.isEmpty{
                    Text("Child Rule")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    ScrollView {
                        Text(venueDetails.childRule)
                            .foregroundColor(.gray)
                            .font(.headline)
                            .frame(maxHeight: venueDetails.childRule.split(separator: "\n").count > 3 ? 100 : .infinity)
                    }
                }
               
                Button(action: {
                    showingMap = true
                }) {
                    Text("Show venue on maps")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 25)
                        .background(Color.red)
                        .cornerRadius(14)
                }
                .fullScreenCover(isPresented: $showingMap) {
                    MapView(latitude: venueDetails.latitude, longitude: venueDetails.longitude)
                        .highPriorityGesture(
                            DragGesture()
                                .onEnded { value in
                                    if value.translation.height > 50 {
                                        self.showingMap = false
                                    }
                                }
                        )
                }

               
            }
        }
    }
}

struct MapView: UIViewRepresentable {
    let latitude: String
    let longitude: String
   
    func makeUIView(context: Context) -> MKMapView {
        MKMapView(frame: .zero)
    }
   
    func updateUIView(_ view: MKMapView, context: Context) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: Double(latitude) ?? 0, longitude: Double(longitude) ?? 0)
        view.addAnnotation(annotation)
        view.setRegion(MKCoordinateRegion(center: annotation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)), animated: true)
    }
}


struct CircularProgressBar: View {
    var progress: Double
    var lineWidth: CGFloat = 12
    var strokeColor = Color.orange
   
    private var normalizedProgress: Double {
        min(max(0, progress), 100) / 100.0
    }
   
    private var animatableData: Double {
        get { normalizedProgress }
        set { progress = newValue * 100.0 }
    }
   
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: lineWidth)
                .opacity(0.3)
                .foregroundColor(strokeColor)
                .frame(width: 45, height: 45)
           
            Text(String(format: "%.0f", progress))
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .bold))
           
            Circle()
                .trim(from: 0.0, to: CGFloat(normalizedProgress))
                .stroke(style: StrokeStyle(lineWidth: lineWidth))
                .foregroundColor(strokeColor)
                .rotationEffect(.degrees(-90))
                .frame(width: 45, height: 45)
        }
        .fixedSize() // Fix the size of the ZStack
    }
}


struct ArtistsListView: View {
    let artistDetails: [ArtistDetails]

    var body: some View {
       
        VStack{
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(artistDetails, id: \.id) { artist in
                        VStack() {
                           
                            VStack {
                                HStack {
                                   
                                    VStack{
                                        VStack(alignment: .leading){
                                            AsyncImage(url: URL(string: artist.artistimage)) { image in
                                                image.resizable()
                                            } placeholder: {
                                                Color.gray
                                            }
                                            .frame(width: 120, height: 120)
                                        }
                                    }.frame(width: 125, height: 125)
                                    VStack(alignment: .leading) {
                                        Text(artist.artistname)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        Text("\(artist.followers) Followers")
                                            .foregroundColor(.white)
                                        //            Text("Spotify link: \(artist.spotifylink)")
                                        HStack {
                                            Button(action: {
                                                guard let url = URL(string: artist.spotifylink) else { return }
                                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                            }) {
                                                Image("spotify_logo")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 45, height: 45)
                                            }
                                            
                                            Text("Spotify")
                                                .foregroundColor(.green)
                                        }
                                        Button(action: {
                                            guard let url = URL(string: artist.spotifylink) else { return }
                                            UIApplication.shared.open(url)
                                        }, label: {
                                            EmptyView()
                                        })
                                    }
                                    VStack (alignment: .leading)
                                    {
                                        Text("Popularity")
                                            .font Weight(.bold)
                                            .foregroundColor(.white)
                                            .font(.headline)
                                       
                                        CircularProgressBar(progress: Double(artist.popularity))
                                       
                                       
                                       
                                    }
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                               
                            }
                            VStack(alignment: .leading) {
                                Text("Popular Albums")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .font(.title2)
                                    .alignmentGuide(.leading) { _ in
                                        0
                                    }
                               
                                HStack {
                                    AsyncImage(url: URL(string: artist.albumlink1)) { image in
                                        image.resizable()
                                    } placeholder: {
                                        Color.gray
                                    }
                                    .frame(width: 100, height: 100)
                                   
                                    AsyncImage(url: URL(string: artist.albumlink2)) { image in
                                        image.resizable()
                                    } placeholder: {
                                        Color.gray
                                    }
                                    .frame(width: 100, height: 100)
                                   
                                    AsyncImage(url: URL(string: artist.albumlink3)) { image in
                                        image.resizable()
                                    } placeholder: {
                                        Color.gray
                                    }
                                    .frame(width: 100, height: 100)
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                        .padding(.vertical, 8)
                        .background(Color.gray)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
}
