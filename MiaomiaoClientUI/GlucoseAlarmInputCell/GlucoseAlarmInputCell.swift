//
//  GlucoseRangeOverrideTableViewCell.swift
//  LoopKit
//
//  Created by Nate Racklyeft on 7/13/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import UIKit


protocol GlucoseAlarmInputCellDelegate: class {
    func glucoseAlarmInputCellDidUpdateValue(_ cell: GlucoseAlarmInputCell)
}


class GlucoseAlarmInputCell: UITableViewCell, UITextFieldDelegate {

    weak var delegate: GlucoseAlarmInputCellDelegate?

    var minValue: Double = 0 {
        didSet {
            minValueTextField.text = valueNumberFormatter.string(from: NSNumber(value: minValue))
        }
    }

   

    lazy var valueNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1

        return formatter
    }()

    var unitString: String? {
        get {
            return unitLabel.text
        }
        set {
            unitLabel.text = newValue
        }
    }

    // MARK: Outlets

    @IBOutlet weak var iconImageView: UIImageView!

    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var unitLabel: UILabel!

    @IBOutlet weak var minValueTextField: UITextField!

    

    // MARK: - UITextFieldDelegate

    func textFieldDidBeginEditing(_ textField: UITextField) {
        DispatchQueue.main.async {
            textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        let value = valueNumberFormatter.number(from: textField.text ?? "")?.doubleValue ?? 0

        switch textField {
        case minValueTextField:
            minValue = value
        
        default:
            break
        }

        delegate?.glucoseAlarmInputCellDidUpdateValue(self)
    }
}
