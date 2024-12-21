import SwiftUI

struct FreewriteView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var manager = JournalEntryManager()
    @State private var content = ""
    private let date = Date()

    var body: some View {
        ZStack {
            // Fullscreen background color
            Color(hex: "#0B1E30").ignoresSafeArea()

            VStack(spacing: 10) {
                // Top Row: Yellow Back Arrow
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: "#FFFFFF")) // Star Glow Yellow
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20) // Adjust top padding to align correctly

                // FREEWRITE, Date, and Checkmark
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("FREEWRITE")
                            .font(.system(size: 14, weight: .bold))
                            .kerning(1.5)
                            .foregroundColor(Color(hex: "#F8C471")) // Star Glow Yellow

                        Text(formattedDate())
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(hex: "#D4DDE1")) // Moonlight Silver
                    }

                    Spacer()

                    Button(action: {
                        manager.addEntry(
                            title: "Freewrite - \(formattedDate())",
                            content: content,
                            type: "Freewrite"
                        )
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: "#F8C471")) // Star Glow Yellow
                    }
                }
                .padding(.horizontal, 20)

                // TextEditor with placeholder
                ZStack(alignment: .topLeading) {
                    if content.isEmpty {
                        Text("What was the best part about today?\nWhat's been on your mind lately?")
                            .foregroundColor(Color.gray.opacity(0.6))
                            .padding(.horizontal, 12)
                            .padding(.top, 12)
                    }
                    TextEditor(text: $content)
                        .foregroundColor(Color.white) // Text color
                        .background(Color.clear) // Transparent background
                        .scrollContentBackground(.hidden) // Remove default background
                        .padding(4)
                }
                .frame(maxHeight: .infinity)
                .background(Color(hex: "#0B1E30")) // Blue background
                .cornerRadius(12)
                .padding(.horizontal, 16)

                Spacer()
            }
        }
        .navigationBarHidden(true) // Hides the navigation bar
    }

    // Format the date
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
}

struct FreewriteView_Previews: PreviewProvider {
    static var previews: some View {
        FreewriteView()
    }
}
