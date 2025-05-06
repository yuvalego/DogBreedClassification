import SystemConfiguration.CaptiveNetwork
import SwiftUI
import UIKit
import Foundation

// MARK: - UIKit camera wrapper
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage { parent.image = uiImage }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}
import PhotosUI

// MARK: - Breed Detail Structures
struct BreedDetail: Codable {
    let general_info: GeneralInfo
    let intelligence: Intelligence
    let hygiene: Hygiene
    let owner_suitability: OwnerSuitability
    let living_environment: LivingEnvironment
    let energy: Energy
    let sociability: Sociability
}

struct GeneralInfo: Codable {
    let Breed_name: String
    let Life_expectancy: String
    let Average_weight: String
    let Average_height: String
    let Breed_group: String
    let Origin: String
    let Common_colors: String
    let Coat_type: String
}

struct Intelligence: Codable {
    let Learning_speed: Double
    let Obedience_level: Double
    let Responsiveness: Double
    let Overall_justification: String
}

struct Hygiene: Codable {
    let Shedding_level: Double
    let Grooming_effort: Double
    let Bathing_frequency: Double
    let Overall_justification: String
}

struct OwnerSuitability: Codable {
    let First_time_owner_suitability: Double
    let Patience_required: Double
    let Training_consistency: Double
    let Overall_justification: String
}

struct LivingEnvironment: Codable {
    let Apartment_suitability: Double
    let Barking_tendency: Double
    let Space_requirement: Double
    let Overall_justification: String
}

struct Energy: Codable {
    let Exercise_needs: Double
    let Playfulness: Double
    let Mental_stimulation: Double
    let Overall_justification: String
}

struct Sociability: Codable {
    let Good_with_children: Double
    let Other_pet_compatibility: Double
    let Stranger_friendliness: Double
    let Overall_justification: String
}

// MARK: - Helper Models
struct BreedInfo {
    let breedName: String
    let categoryScores: [String: Double]
    let fullDetail: BreedDetail
}

// MARK: - Helper Functions
func loadJSONData() -> Data? {
    guard let fileURL = Bundle.main.url(forResource: "breed_info", withExtension: "json") else {
        print("❌ Could not find breed_info.json")
        return nil
    }
    return try? Data(contentsOf: fileURL)
}
import Foundation

func getAddress() -> String? {
    var address: String?

    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    if getifaddrs(&ifaddr) == 0 {
        var ptr = ifaddr
        while let currentPtr = ptr {
            defer { ptr = currentPtr.pointee.ifa_next }

            let interface = currentPtr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family

            if addrFamily == UInt8(AF_INET),
               let name = String(validatingUTF8: interface.ifa_name),
               name == "en0" {

                let addr = interface.ifa_addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
                    $0.pointee
                }
                let ip = inet_ntoa(addr.sin_addr)
                if let ip = ip {
                    address = String(cString: ip)
                }
                break
            }
        }
        freeifaddrs(ifaddr)
    }
    return address
}


func predictBreedName(from image: UIImage) async -> String? {
    let serverIP = "172.20.10.2"
    guard let imageData = image.jpegData(compressionQuality: 0.8),
          let url = URL(string: "http://\(serverIP):8000/predict") else {
        return nil
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
    request.httpBody = imageData

    do {
        let (data, _) = try await URLSession.shared.data(for: request)
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let breed = json["breed"] as? String {
            return breed
        }
    } catch {
        print("❌ Error predicting breed:", error)
    }
    return nil
}

func getBreedInfo(_ breedName: String) -> BreedInfo? {
    guard let jsonData = loadJSONData() else { return nil }
    let decoder = JSONDecoder()
    guard let breedsDatabase = try? decoder.decode([String: BreedDetail].self, from: jsonData),
          let breedInfo = breedsDatabase[breedName] else { return nil }
    
    let intelligenceAvg = (breedInfo.intelligence.Learning_speed + breedInfo.intelligence.Obedience_level + breedInfo.intelligence.Responsiveness) / 3.0
    let hygieneAvg = (breedInfo.hygiene.Shedding_level + breedInfo.hygiene.Grooming_effort + breedInfo.hygiene.Bathing_frequency) / 3.0
    let ownerSuitabilityAvg = (breedInfo.owner_suitability.First_time_owner_suitability + breedInfo.owner_suitability.Patience_required + breedInfo.owner_suitability.Training_consistency) / 3.0
    let livingEnvironmentAvg = (breedInfo.living_environment.Apartment_suitability + breedInfo.living_environment.Barking_tendency + breedInfo.living_environment.Space_requirement) / 3.0
    let energyAvg = (breedInfo.energy.Exercise_needs + breedInfo.energy.Playfulness + breedInfo.energy.Mental_stimulation) / 3.0
    let sociabilityAvg = (breedInfo.sociability.Good_with_children + breedInfo.sociability.Other_pet_compatibility + breedInfo.sociability.Stranger_friendliness) / 3.0
    
    let categoryScores = [
        "Intelligence": intelligenceAvg,
        "Hygiene": hygieneAvg,
        "Owner Suitability": ownerSuitabilityAvg,
        "Living Environment": livingEnvironmentAvg,
        "Energy": energyAvg,
        "Sociability": sociabilityAvg
    ]
    return BreedInfo(breedName: breedInfo.general_info.Breed_name, categoryScores: categoryScores, fullDetail: breedInfo)
}
func getApiStatus() -> Bool {
    let serverIP = "172.20.10.2" // ipconfig getifaddr en0
    guard let url = URL(string: "http://\(serverIP):8000/") else {
        return false
    }

    var isApiConnected = false
    let semaphore = DispatchSemaphore(value: 0)

    URLSession.shared.dataTask(with: url) { _, _, error in
        if error != nil {
            isApiConnected = false
        } else {
            isApiConnected = true
        }
        semaphore.signal()
    }.resume()

    semaphore.wait()
    return isApiConnected
}

// MARK: - Detailed Explanation View
struct DetailedExplanationView: View {
    let breedDetail: BreedDetail

    // Expansion state for each card
    @State private var showIntelligence = false
    @State private var showHygiene = false
    @State private var showOwnerSuitability = false
    @State private var showLivingEnvironment = false
    @State private var showEnergy = false
    @State private var showSociability = false

    // Collapse all cards helper
    private func collapseAll() {
        showIntelligence = false
        showHygiene = false
        showOwnerSuitability = false
        showLivingEnvironment = false
        showEnergy = false
        showSociability = false
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Intelligence Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Intelligence")
                            .font(.headline)
                        Spacer()
                        Image(systemName: showIntelligence ? "chevron.up" : "chevron.down")
                    }
                    if showIntelligence {
                        Text(breedDetail.intelligence.Overall_justification)
                            .font(.body)
                            .padding(.top, 4)
                            .transition(.opacity)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                .onTapGesture {
                    let newState = !showIntelligence
                    withAnimation(.easeInOut(duration: 0.3)) {
                        collapseAll()
                        showIntelligence = newState
                    }
                }

                // Hygiene Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Hygiene")
                            .font(.headline)
                        Spacer()
                        Image(systemName: showHygiene ? "chevron.up" : "chevron.down")
                    }
                    if showHygiene {
                        Text(breedDetail.hygiene.Overall_justification)
                            .font(.body)
                            .padding(.top, 4)
                            .transition(.opacity)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                .onTapGesture {
                    let newState = !showHygiene
                    withAnimation(.easeInOut(duration: 0.3)) {
                        collapseAll()
                        showHygiene = newState
                    }
                }

                // Owner Suitability Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Owner Suitability")
                            .font(.headline)
                        Spacer()
                        Image(systemName: showOwnerSuitability ? "chevron.up" : "chevron.down")
                    }
                    if showOwnerSuitability {
                        Text(breedDetail.owner_suitability.Overall_justification)
                            .font(.body)
                            .padding(.top, 4)
                            .transition(.opacity)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                .onTapGesture {
                    let newState = !showOwnerSuitability
                    withAnimation(.easeInOut(duration: 0.3)) {
                        collapseAll()
                        showOwnerSuitability = newState
                    }
                }

                // Living Environment Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Living Environment")
                            .font(.headline)
                        Spacer()
                        Image(systemName: showLivingEnvironment ? "chevron.up" : "chevron.down")
                    }
                    if showLivingEnvironment {
                        Text(breedDetail.living_environment.Overall_justification)
                            .font(.body)
                            .padding(.top, 4)
                            .transition(.opacity)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                .onTapGesture {
                    let newState = !showLivingEnvironment
                    withAnimation(.easeInOut(duration: 0.3)) {
                        collapseAll()
                        showLivingEnvironment = newState
                    }
                }

                // Energy Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Energy")
                            .font(.headline)
                        Spacer()
                        Image(systemName: showEnergy ? "chevron.up" : "chevron.down")
                    }
                    if showEnergy {
                        Text(breedDetail.energy.Overall_justification)
                            .font(.body)
                            .padding(.top, 4)
                            .transition(.opacity)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                .onTapGesture {
                    let newState = !showEnergy
                    withAnimation(.easeInOut(duration: 0.3)) {
                        collapseAll()
                        showEnergy = newState
                    }
                }

                // Sociability Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Sociability")
                            .font(.headline)
                        Spacer()
                        Image(systemName: showSociability ? "chevron.up" : "chevron.down")
                    }
                    if showSociability {
                        Text(breedDetail.sociability.Overall_justification)
                            .font(.body)
                            .padding(.top, 4)
                            .transition(.opacity)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                .onTapGesture {
                    let newState = !showSociability
                    withAnimation(.easeInOut(duration: 0.3)) {
                        collapseAll()
                        showSociability = newState
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Detailed Explanation")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var breedInfo: BreedInfo?
    @State private var isPickerPresented = false
    @State private var showMoreInfo = false
    @State private var animateBars = false
    @State private var isCamera = false
    @State private var isApiConnected = getApiStatus()
    @State private var proceedWithoutApi = false
    @State private var showGeneralInfo = false  // Toggle between characteristics & general info
    @State private var isCameraPresented = false

    var body: some View {
        NavigationStack {
            if !isApiConnected && !proceedWithoutApi {
                // Show warning if API connection is not available
                VStack {
                    Text("⚠️ API Connection Required")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()

                    Text("In order to proceed, you need a working API connection. Otherwise you won't be able to view the breed information.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .padding()
                .background(Color.black)
                .cornerRadius(12)
                .shadow(radius: 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: showMoreInfo ? 10 : 30) {
                    if selectedImage == nil {
                        VStack(spacing: 24) {
                            Text("Welcome!")
                                .font(.largeTitle.bold())
                                .multilineTextAlignment(.center)

                            Text("Please upload or take an image of a dog to continue.")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                            // Menu replaces ActionSheet for direct pop-up from the button
                            Menu {
                                Button(action: {
                                    isCamera = false
                                    isPickerPresented = true
                                }) {
                                    Label("Upload Image", systemImage: "photo")
                                }
                                Button(action: {
                                    isCamera = true
                                    isCameraPresented = true
                                }) {
                                    Label("Take a Picture", systemImage: "camera")
                                }
                            } label: {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(width: 200, height: 200)
                                    .overlay(
                                        Image(systemName: "dog.fill")
                                            .font(.system(size: 50, weight: .medium))
                                            .foregroundColor(.gray)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding()
                        .photosPicker(
                            isPresented: $isPickerPresented,
                            selection: $selectedItem,
                            matching: .images,
                            preferredItemEncoding: .automatic
                        )
                    } else {
                        VStack(spacing: 20) {
                            HStack(spacing: 20) {
                                VStack(spacing: 8) {
                                    if let selectedImage = selectedImage {
                                        Image(uiImage: selectedImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 150, height: 150)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                            .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                                    }
                                    // Menu replaces ActionSheet for Change Image
                                    Menu {
                                        Button(action: {
                                            isCamera = false
                                            isPickerPresented = true
                                        }) {
                                            Label("Upload Image", systemImage: "photo")
                                        }
                                        Button(action: {
                                            isCamera = true
                                            isCameraPresented = true
                                        }) {
                                            Label("Take a Picture", systemImage: "camera")
                                        }
                                    } label: {
                                        Text("Change Image")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                VStack(alignment: .center, spacing: 16) {
                                    if let breedInfo = breedInfo {
                                        Text(breedInfo.breedName)
                                            .font(.title2.bold())
                                            .multilineTextAlignment(.center)
                                            .foregroundStyle(.primary)

                                        Button(action: {
                                            withAnimation {
                                                showMoreInfo.toggle()
                                                if showMoreInfo {
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                                        withAnimation(.easeOut(duration: 0.6)) {
                                                            animateBars = true
                                                        }
                                                    }
                                                } else {
                                                    animateBars = false
                                                }
                                            }
                                        }) {
                                            Text(showMoreInfo ? "Hide Info" : "More Info")
                                                .fontWeight(.semibold)
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(Color.accentColor)
                                                .foregroundColor(.white)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding()

                            if showMoreInfo, let breedInfo = breedInfo {
                                Divider()

                                if !showGeneralInfo {
                                    // Breed Characteristics section with swipeable graphs
                                    Text("Breed Characteristics")
                                        .font(.title3.bold())
                                        .frame(maxWidth: .infinity, alignment: .center)

                                    TabView {
                                        // Bar Graph
                                        VStack(alignment: .leading, spacing: 16) {
                                            ForEach(breedInfo.categoryScores.sorted(by: { $0.key < $1.key }), id: \.key) { category, score in
                                                VStack(alignment: .leading) {
                                                    Text(category)
                                                        .font(.subheadline)
                                                    ZStack(alignment: .leading) {
                                                        RoundedRectangle(cornerRadius: 6)
                                                            .fill(Color.gray.opacity(0.3))
                                                            .frame(height: 10)
                                                        RoundedRectangle(cornerRadius: 6)
                                                            .fill(Color.accentColor)
                                                            .frame(width: animateBars ? CGFloat(score / 10) * 200 : 0, height: 10)
                                                            .animation(.easeOut(duration: 0.6), value: animateBars)
                                                    }
                                                }
                                            }
                                        }
                                        .padding()

                                        // Radar Graph
                                        RadarChartView(
                                            categories: Array(breedInfo.categoryScores.keys.sorted()),
                                            scores: breedInfo.categoryScores.sorted(by: { $0.key < $1.key }).map { $0.value },
                                            animate: true
                                        )
                                        .frame(height: 300)
                                        .padding()
                                    }
                                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                                    .frame(maxHeight: 350)
                                } else {
                                    // General Information section
                                    Text("General Information")
                                        .font(.title3.bold())
                                        .frame(maxWidth: .infinity, alignment: .center)

                                    // Minimalistic two-column grid for General Information
                                    let info = breedInfo.fullDetail.general_info
                                    let infoItems = [
                                        ("Breed Group", info.Breed_group),
                                        ("Life Expectancy", info.Life_expectancy),
                                        ("Origin", info.Origin),
                                        ("Coat Type", info.Coat_type),
                                        ("Avg Height", info.Average_height),
                                        ("Avg Weight", info.Average_weight)
                                    ]

                                    let columns = [
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ]

                                    ScrollView {
                                        LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                                            ForEach(infoItems, id: \.0) { label, value in
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(label)
                                                        .font(.caption)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(.secondary)
                                                    Text(value)
                                                        .font(.body)
                                                        .fontWeight(.medium)
                                                }
                                                .padding(8)
                                                .background(Color.gray.opacity(0.05))
                                                .cornerRadius(8)
                                            }
                                        }
                                        .padding()
                                    }
                                }

                                // Toggle between characteristics and general info sections
                                Toggle(isOn: $showGeneralInfo) {
                                    Text(showGeneralInfo ? "Show Breed Characteristics" : "Show General Information")
                                        .fontWeight(.medium)
                                }
                                .padding()

                                // Always-present Detailed Explanation button
                                NavigationLink(destination: DetailedExplanationView(breedDetail: breedInfo.fullDetail)) {
                                    Text("Detailed Explanation")
                                        .font(.system(size: 18))
                                        .foregroundColor(.accentColor)
                                        .padding(.top, -10)
                                }
                            }
                        }
                        .photosPicker(
                            isPresented: $isPickerPresented,
                            selection: $selectedItem,
                            matching: .images,
                            preferredItemEncoding: .automatic
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .toolbar {
                    if selectedImage != nil {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                withAnimation {
                                    selectedImage = nil
                                    selectedItem = nil
                                    breedInfo = nil
                                    showMoreInfo = false
                                    animateBars = false
                                }
                            }) {
                            }
                        }
                    }
                }
                .animation(.easeInOut, value: showMoreInfo)
                .animation(.easeInOut, value: selectedImage)
                .sheet(isPresented: $isCameraPresented) {
                    ImagePicker(image: $selectedImage)
                }
                .onChange(of: selectedItem) {
                    Task {
                        if let data = try? await selectedItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            selectedImage = uiImage
                            if let predictedName = await predictBreedName(from: uiImage) {
                                breedInfo = getBreedInfo(predictedName)
                            }
                            // Trigger bar graph animation on new image
                            if showMoreInfo {
                                animateBars = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    withAnimation(.easeOut(duration: 0.6)) {
                                        animateBars = true
                                    }
                                }
                            }
                        }
                    }
                }
                .onChange(of: selectedImage) { _, uiImage in
                    guard let uiImage else { return }
                    Task {
                        if let predictedName = await predictBreedName(from: uiImage) {
                            breedInfo = getBreedInfo(predictedName)
                        }
                        if showMoreInfo {
                            animateBars = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.easeOut(duration: 0.6)) { animateBars = true }
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
