//
//  pickercell.swift
//  
//
//  Created by Bjørn Inge Berg on 23/04/2019.
//

import UIKit

class pickercell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style:style, reuseIdentifier: reuseIdentifier)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        NSLog("dabear:: required init")
        super.init(coder: aDecoder)
        
        //pickerleft.
        
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBOutlet weak var pickerleft: UIPickerView!
    @IBOutlet weak var pickerright: UIPickerView!
}
