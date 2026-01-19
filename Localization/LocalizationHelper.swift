//
//  LocalizationHelper.swift
//  TheVoice
//
//  Created by Yany Gonzalez Yepez on 1/18/26.
//

import Foundation

extension String {
    var localized: String{
        return NSLocalizedString(self, comment: "")
    }
}

