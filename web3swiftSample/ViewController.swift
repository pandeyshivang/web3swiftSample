//
//  ViewController.swift
//  web3swiftSample
//
//  Created by Shivang Pandey on 21/03/18.
//  Copyright © 2018 Shivang Pandey. All rights reserved.
//

import UIKit
import web3swift
import BigInt
var ethAddressKey:String = "ETH_ADDRESS"
class ViewController: UIViewController {
    var address:String?
    let contractAddress = EthereumAddress("0xCea6B46465b6DbDE79d27Ee50c3D8b5D2F139585")
    @IBOutlet weak var addressTxt: UITextView!
    @IBOutlet weak var balanceETH: UILabel!
    @IBOutlet weak var toAddressTxt: UITextField!
    @IBOutlet weak var amountTxt: UITextField!
    @IBOutlet weak var tokenBalLabel: UILabel!
    var web3Rinkeby:web3?
    
    var bip32keystore:BIP32Keystore?
    var keystoremanager:KeystoreManager?
    var contract:web3.web3contract?
    var tokenName:String?
    override func viewDidLoad() {
        super.viewDidLoad()
        web3Rinkeby = Web3.InfuraRinkebyWeb3()
        let userDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let path = userDir+"/keystore/"
        keystoremanager =  KeystoreManager.managerForPath(path, scanForHDwallets: true, suffix: "json")
        
        self.web3Rinkeby?.addKeystoreManager(self.keystoremanager)
        self.bip32keystore = self.keystoremanager?.bip32keystores[0]
        
        self.address = self.bip32keystore?.addresses?.first?.address
        addressTxt.text = address
//        do {
//
//            let privatekey = try keystoremanager?.UNSAFE_getPrivateKeyData(password: "1234", account: (keystoremanager?.addresses?.first)!)
//            print("pkey",privatekey?.toHexString())
//            let etheriumKeystore = try EthereumKeystoreV3.init(privateKey: privatekey!, password: "1234")
//            print("ether address",etheriumKeystore?.addresses?.first?.address)
//        } catch  {
//            print(error.localizedDescription)
//        }
//        print("myadress",self.address)
        let ethAdd = EthereumAddress(address ?? "")
        let balancebigint = web3Rinkeby?.eth.getBalance(address: ethAdd).value
        balanceETH.text = "Ether Balance :\(String(describing: Web3.Utils.formatToEthereumUnits(balancebigint ?? 0)!))"
        let gasPriceResult = web3Rinkeby?.eth.getGasPrice()
        guard case .success(let gasPrice)? = gasPriceResult else {return}
        var options = Web3Options()
        options.gasPrice = gasPrice
        options.from = ethAdd
        let parameters = [] as [AnyObject]
        
        self.contract = self.web3Rinkeby?.contract(Web3Utils.erc20ABI, at: self.contractAddress, abiVersion: 2)!
        let intermediate = self.contract?.method("name", parameters:parameters,  options: options)
        guard let tokenNameRes = intermediate?.call(options: options) else {return}
        guard case .success(let result) = tokenNameRes else {return}
        print("token name",result["0"] as! String)
        self.tokenName = result["0"] as? String
        
        
        
        let intermediatedecimal = contract?.method("decimals", parameters:parameters,  options: options)
        guard let decimal = intermediatedecimal?.call(options: options) else {return}
        guard case .success(let resultdeci) = decimal else {return}
        print("result is ",resultdeci["0"] as! BigUInt)
        
        guard let bkxBalanceResult = contract?.method("balanceOf", parameters: [ethAdd] as [AnyObject], options: options)?.call(options: nil) else {return}
        guard case .success(let bkxBalance) = bkxBalanceResult, let bal = bkxBalance["0"] as? BigUInt else {return}
        let tokenBal = (Double(String(bal)) ?? 0.0)/pow(10, 10)
        self.tokenBalLabel.text = "\(tokenName ?? "Not Found") Balance : \(tokenBal)"
        print("token balance = ",tokenBal)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func sendEther(_ sender: UIBarButtonItem) {
        let amount = amountTxt.text ?? ""
        let toaddress = EthereumAddress.init(self.toAddressTxt.text ?? "", type: .normal)
        if (amount != "") && (toaddress.address != "") {
            let alert  = UIAlertController(title: "Enter Password", message: nil, preferredStyle: .alert)
            alert.addTextField(configurationHandler: {
                (textfield) in
                textfield.isSecureTextEntry = true
            })
            let action = UIAlertAction(title: "Proceed", style: .destructive, handler: {
                Void in
                let pass = alert.textFields![0].text ?? ""
                if (pass != "") {
                    let selectCoinAlert = UIAlertController(title: "Select Coin", message: nil, preferredStyle: .actionSheet)
                    let etherAction = UIAlertAction(title: "Ether", style: .default, handler: {
                        _ in
                        var options = Web3Options.defaultOptions()
                        options.gasLimit = BigUInt(21000)
                        
                        options.from = self.bip32keystore?.addresses?.first!
                        let amountDouble = Int((Double(amount) ?? 0.0)*pow(10, 18))
                        let am = BigUInt.init(amountDouble)
                        options.value = am
                        let estimatedGasResult = self.web3Rinkeby?.contract(Web3.Utils.coldWalletABI, at: toaddress)!.method(options: options)!.estimateGas(options: nil)
                        guard case .success(let estimatedGas)? = estimatedGasResult else {return}
                        options.gasLimit = estimatedGas
                        var intermediateSend = self.web3Rinkeby?.contract(Web3.Utils.coldWalletABI, at: toaddress, abiVersion: 2)!.method(options: options)!
                        options.from = self.bip32keystore?.addresses?.first!
                        
                        intermediateSend = self.web3Rinkeby?.contract(Web3.Utils.coldWalletABI, at: toaddress, abiVersion: 2)!.method(options: options)!
                        let sendResultBip32 = intermediateSend?.send(password: pass)
                        switch sendResultBip32 {
                        case .success(let r)?:
                            print("Sucess",r)
                        case .failure(let err)?:
                            print("Eroor",err)
                        case .none:
                            print("sendResultBip32",sendResultBip32)
                        }
                        
                        let realert = UIAlertController(title: "Result is :", message: String(describing: sendResultBip32?.value), preferredStyle: .actionSheet)
                        let copy = UIAlertAction(title: "COPY", style: .cancel, handler: {
                            _ in
                            UIPasteboard.general.string = String(describing: sendResultBip32?.value)
                        })
                        realert.addAction(copy)
                        self.present(realert, animated: true, completion: nil)
                        
                        
                    })
                    let tokenTran = UIAlertAction(title: self.tokenName, style: .default, handler: {
                        _ in
                        guard case .success(let gasPriceRinkeby)? = self.web3Rinkeby?.eth.getGasPrice() else {return}
                        var tokenTransferOptions = Web3Options.defaultOptions()
                        tokenTransferOptions.gasPrice = gasPriceRinkeby
                        tokenTransferOptions.from = self.bip32keystore?.addresses?.first
                        tokenTransferOptions.to = toaddress
                        let amoutDouble = (Double(amount) ?? 0.0)*10000000000
                        let amountStr = String(Int(amoutDouble))
                        let amountBigUInt = BigUInt.init(amountStr)!
                        let intermediateForTokenTransfer = self.contract?.method("transfer", parameters: [toaddress, amountBigUInt] as [AnyObject], options: tokenTransferOptions)!
                        let tokenTransferResult = intermediateForTokenTransfer?.send(password: pass, options: tokenTransferOptions, onBlock: "latest")
                        switch tokenTransferResult {
                        case .success(let res)?:
                            print("Token transfer successful")
                            print(res)
                        case .failure(let error)?:
                            print(error)
                        case .none:
                            print("something went wrong",tokenTransferResult?.value)
                        }
                        //
                        
                        let realert = UIAlertController(title: "Result is :", message: String(describing: tokenTransferResult?.value), preferredStyle: .actionSheet)
                        let copy = UIAlertAction(title: "COPY", style: .cancel, handler: {
                            _ in
                            UIPasteboard.general.string = String(describing: tokenTransferResult?.value)
                        })
                        realert.addAction(copy)
                        self.present(realert, animated: true, completion: nil)
                    })
                    selectCoinAlert.addAction(etherAction)
                    selectCoinAlert.addAction(tokenTran)
                    self.present(selectCoinAlert, animated: true, completion: nil)
                }else {
                    self.present(alert, animated: true, completion: nil)
                }
            })
            alert.addAction(action)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }else {
            print("Please fill all fields..")
        }
        
    }
    
    
}






