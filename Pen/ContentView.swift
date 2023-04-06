//
//  ContentView.swift
//  Pen
//
//  Created by Cyril Zakka on 4/3/23.
//

import SwiftUI
import Defaults

extension Defaults.Keys {
    static let config = Defaults.Key("Configuration", default: Configuration())
    static let model = Defaults.Key<URL?>("Model URL")
}

struct ContentView: View {
    
    @Default(.config) var config
    @ObservedObject var completer = LLaMAInvoker.shared
    @Environment(\.openURL) var openURL
    @Default(.model) var model
    
    @State private var promptArea = "Write a recipe for chocolate chip cookies"

    func run() {
        config.prompt = promptArea
        completer.complete(config, openURL: openURL)
    }
    
    @ViewBuilder
    var completeButton: some View {
        switch completer.status {
        case .starting(let progress):
            ProgressView(value: progress)
                .progressViewStyle(.circular)
                .controlSize(.small)
                .padding(.trailing, 6)
        case .working:
            ProgressView()
                .controlSize(.small)
                .padding(.trailing, 3)
        default:
            Button(action: run) { Label("Run", systemImage: "play.fill") }
                .keyboardShortcut("R")
                .disabled(completer.status == .missingModel)
        }
    }
    
    var body: some View {
        NavigationSplitView {
            ControlView(prompt: promptArea, config: $config, model: $model, contextLength: completer.contextLength)
                .navigationSplitViewColumnWidth(min: 250, ideal: 300)
        } detail: {
            TextEditor(text: $promptArea)
                .font(.body)
                .fontDesign(.rounded)
                .scrollContentBackground(.hidden)
                .lineSpacing(10)
                .padding()
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        completeButton
                    }
                }
        }.onAppear {
            if let model {
                completer.loadModel(at: model)
            }
        }
        .onChange(of: model) { model in
            if let model {
                completer.loadModel(at: model)
            }
        }
        .onChange(of: completer.status) { status in
            switch status {
            case .missingModel, .idle, .working, .starting:
                print("Error")
            case .progress, .done:
                promptArea = completer.status.response!.result
            case .failed(let error):
                print("\(error)")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
