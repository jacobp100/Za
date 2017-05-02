//
//  ViewController.swift
//  Scrabble
//
//  Created by Jacob Parker on 28/09/2016.
//  Copyright © 2016 Jacob Parker. All rights reserved.
//

import UIKit
import SafariServices
import GoogleMobileAds

class ViewController: UIViewController, UITextFieldDelegate, UIPopoverPresentationControllerDelegate {

    typealias DictionaryResource = String
    let SOWPODS: DictionaryResource = "sowpods"
    let TWL06: DictionaryResource = "twl06"

    @IBOutlet var adView: GADBannerView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var wordTitle: UILabel!
    @IBOutlet weak var sowpodsResult: UILabel!
    @IBOutlet weak var twl06Result: UILabel!
    @IBOutlet weak var defineButton: UIButton!
    @IBOutlet weak var wordEntry: UITextField!
    var defaultMargin: CGFloat!

    var dictionaries: [DictionaryResource:DictionaryLookup] = [:]
    var resultLabelsForDictionaries: [DictionaryResource:UILabel] = [:]
    let alphaSet = Set("abcdefghijklmnopqrstuvwxyz".characters)
    var word: String? = nil { didSet {
        wordTitle.text = word ?? "No Word"

        if word == "rmad", adView.superview != nil {
            adView.removeFromSuperview()
        }

        resultLabelsForDictionaries.keys.forEach {
            if let word = word, let dictionary = dictionaries[$0] {
                resultLabelsForDictionaries[$0]?.text = dictionary.hasWord(word) ? "Yes" : "No"
            } else {
                resultLabelsForDictionaries[$0]?.text = "–" // en-dash
            }
        }

        defineButton.isEnabled = word != nil
        wordEntry.text = word ?? ""
    } }
    var noAds = false { didSet {
        if noAds && adView.superview != nil {
            adView.removeFromSuperview()
        }

        if noAds && navigationItem.leftBarButtonItem != nil {
            presentedViewController?.dismiss(animated: true, completion: nil)
            navigationItem.leftBarButtonItem = nil
        }
    } }

    override func viewDidLoad() {
        super.viewDidLoad()

        let defaultCenter = NotificationCenter.default
        defaultCenter.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: NSNotification.Name.UIKeyboardWillShow,
            object: nil
        )
        defaultCenter.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: NSNotification.Name.UIKeyboardWillHide,
            object: nil
        )
        defaultCenter.addObserver(
            self,
            selector: #selector(purchasesChanged),
            name: PurchasesChangedNotification,
            object: nil
        )

        noAds = ScrabbleStore.default.hasNoAds
        if !noAds {
            adView.adUnitID = "ca-app-pub-3165588222284261/8679041434"
            adView.rootViewController = self
            let request = GADRequest()
            request.testDevices = [kGADSimulatorID]
            adView.load(request)
        }

        loadDictionary(SOWPODS)
        loadDictionary(TWL06)

        resultLabelsForDictionaries[SOWPODS] = sowpodsResult
        resultLabelsForDictionaries[TWL06] = twl06Result

        wordEntry.delegate = self
        defaultMargin = bottomConstraint.constant

        wordEntry.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        segue.destination.popoverPresentationController?.delegate = self
    }

    func keyboardWillShow(_ sender: Notification) {
        let info = (sender as NSNotification).userInfo!
        let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height
        bottomConstraint.constant =
            defaultMargin + keyboardSize - bottomLayoutGuide.length

        let duration: TimeInterval = (info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue

        UIView.animate(withDuration: duration, animations: { self.view.layoutIfNeeded() }) 
    }

    func keyboardWillHide(_ sender: Notification) {
        let info = (sender as NSNotification).userInfo!
        let duration: TimeInterval = (info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        bottomConstraint.constant = defaultMargin

        UIView.animate(withDuration: duration, animations: { self.view.layoutIfNeeded() }) 
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let word = wordEntry.text , !word.isEmpty {
            self.word = word
        } else {
            self.word = nil
        }

        return true
    }

    @IBAction func defineDidPress(_ sender: AnyObject) {
        guard let word = self.word else { return }

        let definitionPopup = UIReferenceLibraryViewController.dictionaryHasDefinition(forTerm: word)
            ? UIReferenceLibraryViewController(term: word)
            : SFSafariViewController(url: URL(string: "https://www.google.co.uk/search?q=define:" + word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!)

        present(definitionPopup, animated: true, completion: nil)
    }

    @IBAction func wordEntryChanged(_ sender: UITextField) {
        var text = sender.text?.lowercased() ?? ""
        text = String(text.characters.filter { alphaSet.contains($0) })
        sender.text = text
    }

    @IBAction func clearDidPress(_ sender: AnyObject) {
        word = nil
    }

    fileprivate func loadDictionary(_ resource: DictionaryResource) {
        if let dictionaryPath = Bundle.main.path(forResource: resource, ofType: "txt"),
            let dictionary = DictionaryLookup(path: dictionaryPath) {
            dictionaries[resource] = dictionary
        }
    }

    // MARK: IAP

    func purchasesChanged(_ sender: Notification) {
        noAds = ScrabbleStore.default.hasNoAds
    }

    // MARK: Popover delegate

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
