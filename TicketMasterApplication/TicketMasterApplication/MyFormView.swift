import SwiftUI
import Foundation

//https://server-dot-reactticketmasterapplication.ue.r.appspot.com/events?keyword=${keyword_parsed}&location=${location_parsed}&segmentId=${category_id}&radius=${distance}&autodetectCheck=FALSE


struct Event: Identifiable {
    let id = UUID()
    var categoryImage: String = ""
    var name: String = ""
    var venueName: String = ""
    var date: String = ""
    var time: String = ""
    var eventid: String = ""
}
class EventData: ObservableObject {
    @Published var events: [Event] = []
}


struct EventRow: View {
    let event: [String: Any]
   
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(event["name"] as? String ?? "")
                .font(.headline)
            if let dates = event["dates"] as? [String: Any], let start = dates["start"] as? [String: Any] {
                HStack {
                    Text(start["localDate"] as? String ?? "")
                    Text(start["localTime"] as? String ?? "")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
    }
}


func fetchSuggestions(keyword: String) async throws -> [String] {
   
    let url = URL(string: "https://server-dot-reactticketmasterapplication.ue.r.appspot.com/suggestions?keyword=\(keyword.replacingOccurrences(of: " ", with: "%20"))")!
   
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    var suggestionsArray = [String]()
    if(keyword.isEmpty){
        suggestionsArray = [String]()
    }
    else{
       
        let (data, _) = try await URLSession.shared.data(from: url)
        if let stringData = String(data: data, encoding: .utf8)
        {
           
            if let jsonData = stringData.data(using: .utf8) {
                do{
                    if let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:Any]{
                        if let embedded = jsonObject["_embedded"] as? [String:Any], let attractions = embedded["attractions"] as? [[String:Any]]{
                            print("attractions is", attractions)
                            for attraction in attractions {
                                if let name = attraction["name"] as? String{
                                    print("suggestion is", name)
                                    suggestionsArray.append(name)
                                }
                            }
                           
                        }
                    }
                   
                }
            }
           
        }
       
    }
    return suggestionsArray
   
}



func getEvents(keyword: String, location: String, segmentId: String, radius: String, autodetectCheck: String) async throws -> [Event] {
    let keyword = keyword
    let location = location
    let segmentId = segmentId
    let radius = radius
    let autodetectCheck = autodetectCheck
   
    var eventArray = [Event]() // Create an empty array of Event objects

    let url = URL(string: "https://server-dot-reactticketmasterapplication.ue.r.appspot.com/events?keyword=\(keyword)&location=\(location)&segmentId=\(segmentId)&radius=\(radius)&autodetectCheck=\(autodetectCheck)")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
   
    do {
        print("trying to fetch events")
        let (data, _) = try await URLSession.shared.data(for: request)
        if let stringData = String(data: data, encoding: .utf8) {
//            print("Received data: \(stringData)")
            if let jsonData = stringData.data(using: .utf8) {
                do {
                    if let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:Any] {
                        if let embedded = jsonObject["_embedded"] as? [String:Any], let events = embedded["events"] as? [[String:Any]] {
                            for event in events {
                                var eventObj = Event()
                                if let name = event["name"] as? String {
                                    print("Event name: \(name)")
                                    eventObj.name = name
                                }
                                if let dates = event["dates"] as? [String: Any], let start = dates["start"] as? [String: Any] {
                                    if let localDate = start["localDate"] as? String {
                                        print("Event start date: \(localDate)")
                                        eventObj.date = localDate
                                    }
                                    if let localTime = start["localTime"] as? String {
                                        print("Event start time: \(localTime)")
                                        eventObj.time = localTime
                                    }
                                }
                                if let venue = (event["_embedded"] as? [String:Any])?["venues"] as? [[String: Any]], let venueName = venue[0]["name"] as? String {
                                    print("Venue name: \(venueName)")
                                    eventObj.venueName = venueName
                                }
                                if let images = event["images"] as? [[String: Any]], let imageUrl = images.first?["url"] as? String {
                                    print("Image URL: \(imageUrl)")
                                    eventObj.categoryImage = imageUrl
                                }
                                if let eventid = event["id"] as? String{
                                    eventObj.eventid = eventid
                                    print("eventid is", eventid)
                                }
                                eventArray.append(eventObj)
                            }
                        }
                    }
                } catch {
                    print("Error parsing JSON: \(error.localizedDescription)")
                }
            }
        }
       
    }
    return eventArray // Return the populated array of Event objects
}

func getlocationfromip() async throws -> String{
    let IPINFO_KEY = "4d95682f539a20"
    let url = URL(string: "https://ipinfo.io/?token=\(IPINFO_KEY)")!
    var request = URLRequest(url: url)
    var stringData1 = ""
    request.httpMethod = "GET"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    do {
        print("trying to fetch ipinfo")
        let (data, _) = try await URLSession.shared.data(for: request)
        if let stringData = String(data: data, encoding: .utf8) {
            if let jsonData = stringData.data(using: .utf8) {
                print("JSON DATA IS", jsonData)
                do {
                    if let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:Any] {
                        if let loc = jsonObject["loc"] as? String{
                            print("IPINFO LOCATION IS", loc)
                            stringData1 = loc
                            
                        }
                    }
                }
                
            }
            
            
            
        }
    }
    return stringData1
}



struct FormView: View {
    @State private var events: [Event] = []
    let categories = ["Default", "Music", "Sports", "Arts&Theatre", "Film", "Miscellaneous"]
    let categoryIds = [
        "Default": "",
        "Music": "KZFzniwnSyZfZ7v7nJ",
        "Sports": "KZFzniwnSyZfZ7v7nE",
        "Arts&Theatre": "KZFzniwnSyZfZ7v7na",
        "Film": "KZFzniwnSyZfZ7v7nn",
        "Miscellaneous": "KZFzniwnSyZfZ7v7n1"
    ]
    @State var keyword: String = ""
    @State var distance: String = "10"
    @State private var category = "Default"
    @State var location: String = ""
    @State private var isToggled = false
    @State private var showTable = false
    @State private var autodetectCheck = "FALSE"
    @StateObject var eventData = EventData()
   
    @State private var suggestions: [String] = []
   
    //To keep track of loading status of getevents
    @State private var isLoading = false
   
    @State private var isFavoritesViewPresented = false
   
    //Showing suggestions
    @State private var isShowingSuggestions = false
    
    @State private var showingSuggestions = false
    @State private var showingSuggestionsOnce = false

   
    private func onKeywordEditingChanged(_ isEditing: Bool) async {
        if isEditing {
            if !keyword.isEmpty {
                do {
                    suggestions = try await fetchSuggestions(keyword: keyword.replacingOccurrences(of: " ", with: "%20"))
                } catch {
                    // Handle the error here
                    print("Error fetching suggestions: \(error.localizedDescription)")
                }
            } else {
                suggestions = []
            }
        }
    }
   
    var body: some View {
       
       
        VStack { // wrap the Form and List inside a VStack
            Form {
                Section {
                    VStack {
                        HStack {
                            Text("Keyword:")
                            TextField("Required", text: $keyword)
                                .foregroundColor(keyword == "Required" ? .gray : .black)
                                .onChange(of: keyword) { newKeyword in
                                    Task {
                                        do {
                                            if newKeyword.count == 0{
                                                showingSuggestionsOnce = false
                                            }
                                            if newKeyword.count > 5 && !showingSuggestionsOnce {
                                                showingSuggestionsOnce = true
                                                suggestions = []
                                                showingSuggestions = true
                                                suggestions = try await fetchSuggestions(keyword: newKeyword)
                                            } else {
                                                suggestions = []
                                                showingSuggestions = false
                                            }
                                        } catch {
                                            // Handle the error here
                                            print("Error fetching suggestions: \(error.localizedDescription)")
                                        }
                                    }
                                }
                        }
                    }
                    .fullScreenCover(isPresented: $showingSuggestions) {
                        SuggestionsView(suggestions: $suggestions, keyword: $keyword, showingSuggestions: $showingSuggestions, showingSuggestionsOnce: $showingSuggestionsOnce)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .highPriorityGesture(
                                DragGesture()
                                    .onEnded { value in
                                        if value.translation.height > 50 {
                                            self.showingSuggestions = false
                                        }
                                    }
                            )
                    }

                    HStack {
                        Text("Distance:")
                        TextField("", text: $distance)
                    }
                    HStack {
                        Text("Category")
                            .foregroundColor(.black)
                        Spacer()
                        Picker(selection: $category, label: Text("")) {
                            ForEach(categories, id: \.self) { category in
                                if category == "Default" {
                                    Text(category)
                                        .foregroundColor(.blue)
                                } else {
                                    Text(category)
                                }
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .labelsHidden()
                        .accentColor(.blue)
                    }

                    if !isToggled {
                        HStack {
                            Text("Location:")
                            TextField("Required", text: $location)
                                .foregroundColor(location == "Required" ? .gray : .black)
                        }
                    }
                   
                    HStack(alignment: .center, spacing: 8) {
                        Text("AutoDetect my location")
                            .foregroundColor(.black)
                            .fixedSize()
                        Toggle(isOn: $isToggled) {
                            Text("")
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                        .onChange(of: isToggled) { newValue in
                            if newValue {
                                autodetectCheck = "TRUE"
                                location = ""
                            } else {
                                autodetectCheck = "FALSE"
                                location = ""
                            }
                            print("autodetectCheck is now \(autodetectCheck)")
                        }
                    }
                    HStack {
                        Spacer()
                        VStack{
                            Button(action: {
                                self.showTable = true
                                // Action to perform when "Submit" button is tapped
                                Task {
                                    do {
                                        isLoading = true
                                        print("autodetect check is", autodetectCheck)
                                        if autodetectCheck=="TRUE"{
//                                            print("CALLING IPINFO")
                                            location = try await getlocationfromip()
//                                            print("UPDATED LOCATION IS", location)
                                        }
                                        print("category is", category)
                                        print("category ID is", categoryIds[category] ?? "KZFzniwnSyZfZ7v7n1")
                                        let eventDatatemp = try await getEvents(keyword: keyword.replacingOccurrences(of: " ", with: "%20"), location: location.replacingOccurrences(of: " ", with: "%20"), segmentId: categoryIds[category] ?? "KZFzniwnSyZfZ7v7n1", radius: distance, autodetectCheck: autodetectCheck)
                                        eventData.events = eventDatatemp
                                        isLoading = false
                                        //                                    print("RESPONSE IS", eventData.events)
                                    } catch {
                                        print(error.localizedDescription)
                                    }
                                }
                            }) {
                                Text("Submit")
                                    .frame(width: 100, height: 40)
                                    .background(
                                        (keyword.trimmingCharacters(in: .whitespacesAndNewlines) != "" && keyword != "Required" &&
                                         distance.trimmingCharacters(in: .whitespacesAndNewlines) != "" &&
                                         (isToggled || location.trimmingCharacters(in: .whitespacesAndNewlines) != ""))
                                        ? Color.red
                                        : Color.gray
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .disabled(
                                keyword.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
                                keyword == "Required" ||
                                distance.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
                                (!isToggled && location.trimmingCharacters(in: .whitespacesAndNewlines) == "")
                            )
                            
                        }
                        

                        
                        VStack{
                            Button(action: {
                                // Action to perform when "Clear" button is tapped
                                keyword = ""
                                distance = "10"
                                category = "Default"
                                location = ""
                                self.showTable = false
                                self.isToggled = false
                                
                            }) {
                                Text("Clear")
                                    .frame(width: 100, height: 40)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        Spacer()
                    }
                        
                }
            }.navigationBarTitle("Event Search")
                .navigationBarItems(
                    leading: EmptyView(),
                    trailing: Button(action: {
                        isFavoritesViewPresented.toggle()
                    }) {
                        ZStack {
                            Circle()
                                .stroke(Color.blue, lineWidth: 2)
                                .frame(width: 30, height:30)
                            Image(systemName: "heart.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 15))
                                .padding()
                        }
                    }
                )
                .background(
                    NavigationLink(
                        destination: FavoritesView(),
                        isActive: $isFavoritesViewPresented,
                        label: {
                            EmptyView()
                        }
                    )
                )
            if showTable {
                ZStack {
                    Divider().background(Color.systemGray6).edgesIgnoringSafeArea(.bottom)
                    Color(.systemGray6).edgesIgnoringSafeArea(.all)
                    VStack(alignment: .leading) {
                        Text("Results")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.top)
                            .padding(.leading, 15)
                        Divider()
                            .background(Color(.systemGray6))
                        if isLoading {
                            Spacer()
                            Spacer()
                            VStack(alignment: .leading, spacing: 2) {
                                ProgressView("Please wait...")
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        else if !eventData.events.isEmpty
                        {
                            List(eventData.events.sorted(by: { $0.date < $1.date })) { event in
                                HStack {
                                    
                                    Text("\(event.date) - \(event.time)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    AsyncImage(url: URL(string: event.categoryImage)) { image in
                                        image
                                            .resizable()
                                            .scaledToFit()
                                    } placeholder: {
                                        Image(systemName: "photo")
                                            .foregroundColor(.gray)
                                    }
                                    .frame(width: 50, height: 50)
                                    .padding(.trailing, 10)
                                    
                                    Text(event.name)
                                    Spacer()
                                    Text("\(event.venueName)")
                                        .foregroundColor(.gray)
                                    NavigationLink(destination: DetailView(eventId: event.eventid, venueId: event.venueName)) {
                                    }
                                }
                            }
                            .listStyle(PlainListStyle())
                        }
                        else{
                            Text("No result available")
                                .foregroundColor(Color.red)
                                .padding(.leading, 15)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
                }
                .offset(y: -45)
                
                
                }

            }
            .background(Color.systemGray6)
        }
        
    }


struct SuggestionsView: View {
    @Binding var suggestions: [String]
    @Binding var keyword: String
    @Binding var showingSuggestions: Bool
    @Binding var showingSuggestionsOnce: Bool

    var body: some View {
        VStack {
            if !suggestions.isEmpty {
                Text("SUGGESTIONS")
                    .fontWeight(.bold)
            }
            if suggestions.isEmpty {
                ProgressView()
                Text("loading...")
                    .foregroundColor(Color.gray)
            }
            else {
                List(suggestions, id: \.self) { suggestion in
                    Text(suggestion)
                        .foregroundColor(.black)
                        .onTapGesture {
                            Task {
                                keyword = suggestion
                                suggestions = [] // hide suggestions when a suggestion is selected
                                showingSuggestions = false // hide the fullscreen view
                                showingSuggestionsOnce = true
                            }
                        }
                }
            }
        }
    }
}

