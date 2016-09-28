//
//  ViewController.swift
//  Scrabble
//
//  Created by Jacob Parker on 28/09/2016.
//  Copyright © 2016 Jacob Parker. All rights reserved.
//

import UIKit
import SafariServices

class ViewController: UIViewController, UITextFieldDelegate {

    typealias DictionaryResource = String
    let SOWPODS: DictionaryResource = "sowpods"
    let TWL06: DictionaryResource = "twl06"

    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var wordTitle: UILabel!
    @IBOutlet weak var sowpodsResult: UILabel!
    @IBOutlet weak var twl06Result: UILabel!
    @IBOutlet weak var defineButton: UIButton!
    @IBOutlet weak var wordEntry: UITextField!
    var defaultMargin: CGFloat!

    var dictionaries: [DictionaryResource:DictionaryLookup] = [:]
    var resultLabelsForDictionaries: [DictionaryResource:UILabel] = [:]
    var word: String? = nil { didSet {
        wordTitle.text = word ?? "No Word"

        resultLabelsForDictionaries.keys.forEach {
            if word?.containsEmoji == true {
                resultLabelsForDictionaries[$0]?.text = "🎉"
            } else if let word = word, let dictionary = dictionaries[$0] {
                resultLabelsForDictionaries[$0]?.text = dictionary.hasWord(word) ? "Yes" : "No"
            } else {
                resultLabelsForDictionaries[$0]?.text = "–" // en-dash
            }
        }

        defineButton.enabled = word != nil
        wordEntry.text = word ?? ""
    } }

    override func viewDidLoad() {
        super.viewDidLoad()

        let defaultCenter = NSNotificationCenter.defaultCenter()
        defaultCenter.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIKeyboardWillShowNotification,
            object: nil
        )
        defaultCenter.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIKeyboardWillHideNotification,
            object: nil
        )

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

    func keyboardWillShow(sender: NSNotification) {
        let info = sender.userInfo!
        let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue().height
        bottomConstraint.constant =
            defaultMargin + keyboardSize - bottomLayoutGuide.length

        let duration: NSTimeInterval = (info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue

        UIView.animateWithDuration(duration) { self.view.layoutIfNeeded() }
    }

    func keyboardWillHide(sender: NSNotification) {
        let info = sender.userInfo!
        let duration: NSTimeInterval = (info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        bottomConstraint.constant = defaultMargin

        UIView.animateWithDuration(duration) { self.view.layoutIfNeeded() }
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let word = wordEntry.text where !word.isEmpty {
            self.word = word
        } else {
            self.word = nil
        }

        return true
    }

    @IBAction func defineDidPress(sender: AnyObject) {
        guard let word = self.word else { return }

        let definitionPopup =  UIReferenceLibraryViewController.dictionaryHasDefinitionForTerm(word)
            ? UIReferenceLibraryViewController.init(term: word)
            : SFSafariViewController(URL: NSURL(string: "https://www.google.co.uk/search?q=define:" + word.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!)!)

        definitionPopup.modalPresentationStyle = .FullScreen
        definitionPopup.modalTransitionStyle = .CoverVertical
        definitionPopup.providesPresentationContextTransitionStyle = true

        presentViewController(
            definitionPopup,
            animated: true,
            completion: nil
        )
    }

    @IBAction func wordEntryChanged(sender: UITextField) {
        sender.text = sender.text?.lowercaseString
    }

    @IBAction func clearDidPress(sender: AnyObject) {
        word = nil
    }

    private func loadDictionary(resource: DictionaryResource) {
        if let dictionaryPath = NSBundle.mainBundle().pathForResource(resource, ofType: "txt"),
            let dictionary = DictionaryLookup(path: dictionaryPath) {
            dictionaries[resource] = dictionary
        }
    }
}

extension String {
    var containsEmoji: Bool {
        for scalar in unicodeScalars {
            switch scalar.value {
            case 0x3030, 0x00AE, 0x00A9,// Special Characters
            0x1D000...0x1F77F,          // Emoticons
            0x2100...0x27BF,            // Misc symbols and Dingbats
            0xFE00...0xFE0F,            // Variation Selectors
            0x1F900...0x1F9FF:          // Supplemental Symbols and Pictographs
                return true
            default:
                continue
            }
        }
        return false
    }
}
