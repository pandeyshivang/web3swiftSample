//
//  CreateWalletViewController.swift
//  web3swiftSample
//
//  Created by Shivang Pandey on 22/03/18.
//  Copyright © 2018 Shivang Pandey. All rights reserved.
//

import UIKit
import web3swift
class CreateWalletViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
       
      
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func createNew(_ sender: UIButton) {
        let alert = UIAlertController(title: "Enter Passphrase", message: nil, preferredStyle: .alert)
        alert.addTextField(configurationHandler: {
            (textfield) in
            textfield.placeholder = "Enter Password"
        })
        let genrate = UIAlertAction(title: "Genrate", style: .destructive, handler: {
            _ in
            
            let pass = alert.textFields![0].text
            if pass != ""{
                do{
                    let userDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                    let keystoreManager = KeystoreManager.managerForPath(userDir + "/keystore")
                    var ks: BIP32Keystore?
                    if (keystoreManager?.addresses?.count == 0) {
                        let mnemonic = try! BIP39.generateMnemonics(bitsOfEntropy: 256)!
                        let keystore = try! BIP32Keystore(mnemonics: mnemonic, password: pass ?? "", mnemonicsPassword: String((pass ?? "").reversed()))
                        print("keystore",keystore)
                        ks = keystore
                     //   ks = try EthereumKeystoreV3(password: pass ?? "")
                        let keydata = try JSONEncoder().encode(ks?.keystoreParams)
                        FileManager.default.createFile(atPath: userDir + "/keystore"+"/key.json", contents: keydata, attributes: nil)
                        
                       
                    } else {
                        ks = keystoreManager?.walletForAddress((keystoreManager?.addresses![0])!) as? BIP32Keystore
                    }
                    guard let sender = ks?.addresses?.first else {return}
                    print(sender)

                    let controller = self.storyboard?.instantiateViewController(withIdentifier: "MainViewController")
                    self.present(controller!, animated: true, completion: nil)
                }catch{
                    print(error.localizedDescription)
                }
            }else{
                self.present(alert, animated: true, completion: nil)
            }
            
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(genrate)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    @IBAction func restore(_ sender: UIButton) {
        let alert = UIAlertController(title: "Enter Mnemonics Key", message: nil, preferredStyle: .alert)
        alert.addTextField(configurationHandler: {
            (textfiled) in
            textfiled.placeholder = "Enter mnemonics"
        })
        alert.addTextField(configurationHandler: {
            (textfield) in
            textfield.placeholder = "Enter Password"
            textfield.isSecureTextEntry = true
        })
        let genrate = UIAlertAction(title: "Genrate", style: .destructive, handler: {
            _ in
            let mnemonictxt = alert.textFields![0].text
            let passwordtxt = alert.textFields![1].text
            if mnemonictxt != "" && passwordtxt != "" {
                do{
                    let userDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                    let keystoreManager = KeystoreManager.managerForPath(userDir + "/keystore")
                    var ks: BIP32Keystore?
                    if (keystoreManager?.addresses?.count == 0) {
                        print("mnemonics",mnemonictxt)
                        ks = try! BIP32Keystore(mnemonics: mnemonictxt ?? "", password: passwordtxt ?? "", mnemonicsPassword: String((passwordtxt ?? "").reversed()))
                        let keydata = try JSONEncoder().encode(ks!.keystoreParams)
                        FileManager.default.createFile(atPath: userDir + "/keystore"+"/key.json", contents: keydata, attributes: nil)
                    } else {
                        ks = keystoreManager?.walletForAddress((keystoreManager?.addresses![0])!) as! BIP32Keystore
                    }
                    guard let sender = ks?.addresses?.first else {return}
                    print(sender)
                    let controller = self.storyboard?.instantiateViewController(withIdentifier: "MainViewController")
                    self.present(controller!, animated: true, completion: nil)
                }catch{
                    print(error.localizedDescription)
                }
            }else {
                self.present(alert, animated: true, completion: nil)
            }
        })
        alert.addAction(genrate)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
