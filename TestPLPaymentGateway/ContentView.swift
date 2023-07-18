//
//  ContentView.swift
//  TestPLPaymentGateway
//
//  Created by Hassan Ayoub on 01/05/2023.
//

import SwiftUI
// 1) Installation: after import the framework using pod.
import PLPaymentGateway

struct ContentView: View {
    @State var showWebView = false
    @State var transactionNo : String?

    @State var data: [Any] = []
    @State var showAlert = false
    @State private var readyToNavigate : Bool = false
    @State var gateway = PaylinkGateway(environment: PaylinkGateway.Environment.test)
    @State private var bgColor = Color(uiColor: UIColor(red: 0xFF, green: 0xFF, blue: 0xFF))
    
    func setup() {
        // 2) Create the Payment gateway class
        self.gateway = PaylinkGateway(environment: PaylinkGateway.Environment.test)
    }
        
    var body: some View {
        bgColor.ignoresSafeArea()
            .background(Color.white)
            .overlay {
                NavigationStack {
                    VStack {
                        Image(systemName: "globe")
                            .imageScale(.large)
                            .foregroundColor(.accentColor)
                        Text("Hello Merchant").padding(EdgeInsets(top: 10, leading: 10, bottom: 100, trailing: 10))
                        Button("Pay Now") {
                            // Step 3) Call the backend server to create invoice from the backend and get the transactionNo
                            payInvoice { transNo in
                                transactionNo = transNo
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .overlay(RoundedRectangle(cornerRadius: 0)
                            .stroke(bgColor, lineWidth: 2))
                        .background(Color.white)
                        
                    }
                    .background(bgColor)
                    .ignoresSafeArea()
                    .padding()
                }
                .background(Color.white)
            }
            .onAppear() {
                setup()
            }.sheet(item: $transactionNo) { tranNo in
                // Step 4.a) Get Payment View for SwiftUI: To use SwiftUI and want to display the payment form within the SwiftUI tree. Use the method getPaymentFormView to retrieve the payment form view. Pass the transactionNo got from backend
                gateway.getPaymentFormView(transactionNo: tranNo) {
                    // Step 5.a) After payment is completed (Paid or Declined), orderNumber and transactionNo is returned.
                    orderNum, transNo in
                    
                    transactionNo = nil // to close the sheet.
                    
                    // Step 6.a) Pass the transactionNo to the backend server to check the payment status
                    // (https://paylinksa.readme.io/docs/order-request)
                    checkPayment(transactionNo: transNo) {
                        // Step 7.a) received the status from the backend server.
                        status in
                        //
                        print("order status is: \(status)")
                    }
                }
            }
            .background(Color.white)
//            .alert(isPresented: $showAlert) {
//                Alert(
//                    title: Text("Alert"),
//                    message: Text("Order number \(self.orderNumber!) and Transaction No \(self.transactionNo!)"),
//                    dismissButton: .default(Text("OK"))
//                )
//            }
    }
    
    func openViewController(viewController: UIViewController, url : URL) {
        // Step 4.b) Open Payment View Controller
        gateway.openPaymentForm(transactionNo: self.transactionNo!, from: viewController) {
            result in
            switch result {
            // Step 5.a) After payment is completed (Paid or Declined), orderNumber and transactionNo is returned.
            case .success((let orderNumber, let transactionNo)):
                print("order number: \(orderNumber)")
                // Step 6.a) Pass the transactionNo to the backend server to check the payment status
                checkPayment(transactionNo: transactionNo) {
                    // Step 7.a) received the status from the backend server.
                    orderStatus in
                    print("order status is: \(orderStatus)")
                }
                break;
            case .failure(_):
                break;
            }
        } loaded: {
            // .. code when the ViewController got loaded.
        }
    }
    
    
    func payInvoice(completion: @escaping (_ transactionNo: String) -> Void) {
        let endpointURL = URL(string: "https://demo.paylink.sa/addinvoice.php")!
        let task = URLSession.shared.dataTask(with: endpointURL) { (data, response, error) in
            guard let data = data else {
                if let error = error {
                    print("Error: \(error)")
                }
                return
            }
            do {
                // Parse the JSON response
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let transactionNo = json["transactionNo"] as? String {
                    // Use the transactionNo value
                    print("Transaction No: \(transactionNo)")
                    completion(transactionNo)
                }
            } catch {
                print("JSON parsing error: \(error)")
            }
        }
        task.resume()
    }
    
    func checkPayment(transactionNo: String, completion: @escaping (_ orderStatus: String ) -> Void) {
        let endpointURL = URL(string: "https://demo.paylink.sa/getinvoice.php?transactionNo=\(transactionNo)")!
        
        let task = URLSession.shared.dataTask(with: endpointURL) { (data, response, error) in
            guard let data = data else {
                if let error = error {
                    print("Error: \(error)")
                }
                return
            }
            
            do {
                // Parse the JSON response
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let orderStatus = json["orderStatus"] as? String {
                    // Use the orderStatus value
                    print("orderStatus No: \(orderStatus)")
                    completion(orderStatus)
                }
            } catch {
                print("JSON parsing error: \(error)")
            }
        }
        
        task.resume()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension String: Identifiable {
    public var id: String { return self }
}
