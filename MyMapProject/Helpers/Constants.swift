//
//  Constants.swift
//  MyMapProject
//
//  Created by Enes Kılıç on 3.11.2020.
//  Copyright © 2020 Enes Kılıç. All rights reserved.
//

import Foundation

struct K {
    static let appName = "Maps To Do"
    
    struct ErrorMessages {
        static let deletingCornerErrorMessage = NSLocalizedString("You need to select a corner and then tap the “x” button.", comment: "")
        static let tooFewCornerCountForFieldErrorMessage = NSLocalizedString(" Field cannot contain 2 or less corners.", comment: "")
        static let tooFewCornerCountForLineErrorMessage = NSLocalizedString(" Line must contain 1 or more markers.", comment: "")
        static let navigationControllerDoesNotExistErrorMessage = NSLocalizedString("Navigation controller does not exist.", comment: "")
    }
    
    struct ImagesFromXCAssets {
        static let picture = "picture"
        static let picture1 = "picture1"
        static let picture2 = "picture2"
        static let picture7 = "picture7"
        static let line3 = "line3"
        static let place8 = "place8"
        static let appLogo = "appLogo"
        static let normal = "normal"
        static let terrain = "terrain"
        static let satalite = "satalite"
        static let googleIcon = "googleIcon"
        static let appleIcon = "appleIcon"
        static let mailIcon = "mailIcon"
        
        struct MapImages {
            static let retroMap = "retroMap"
            static let aubergineMap = "aubergineMap"
            static let darkMap = "darkMap"
            static let nightMap = "nightMap"
            static let silverMap = "silverMap"
            static let standartMap = "standartMap"
        }
    }
    
    static let errorSavingContext = NSLocalizedString("Error saving context, ", comment: "")
    
    static let deleteGroupWithAllFields = NSLocalizedString("All fields in this group will be deleted.", comment: "")
    
    struct MapTypes {
        static let normal = "normal"
        static let satellite = "satellite"
        static let terrain = "terrain"
        static let custom = "custom"
    }
    
    struct SystemImages {
        static let minusCircleFill = "minus.circle.fill"
        static let plusCircleFill = "plus.circle.fill"
        static let dotCircle = "dot.circle"
        static let circleFill = "circle.fill"
        static let circleGrid3x3Fill = "circle.grid.3x3.fill"
        static let pipRemove = "pip.remove"
        static let trashFill = "trash.fill"
        static let rectangleAndPencilAndEllipsisrtl = "rectangle.and.pencil.and.ellipsis.rtl"
        static let locationFill = "location.fill"
        static let infoCircleFill = "info.circle.fill"
        static let plus = "plus"
        static let personFillXmark = "person.fill.xmark"
        static let personFillCheckmark = "person.fill.checkmark"
        static let building2CropCircle = "building.2.crop.circle"
        static let person3fill = "person.3.fill"
        static let docRichtextFillHe = "doc.richtext.fill.he"
    }
    
    struct SegueIdentifiers {
        static let goToItemsFromMapView = "goToItemsFromMapView"
        static let infoView = "infoView"
        static let goToGroups = "goToGroups"
        static let goToLines = "goToLines"
        static let goToPlaces = "goToPlaces"
        static let goToLoginViewController = "goToLoginViewController"
        static let goToSettings = "goToSettings"
        static let goToItems = "goToItems"
        static let lineListToMapView = "lineListToMapView"
        static let placeListToMapView = "placeListToMapView"
        static let goToItemsForm = "goToItemsForm"
        static let goToInfoViewController = "goToInfoViewController"
        static let goToAuthViewController = "goToAuthViewController"
        static let backToMapView = "backToMapView"
        static let loginToMapView = "loginToMapView"
        static let goToTeamViewController = "goToTeamViewController"
        static let goToMembershipViewController = "goToMembershipViewController"
        static let goToPermissionsViewController = "goToPermissionsViewController"
        static let mapViewToInfoView = "mapViewToInfoView"
        static let mapViewToPremiumView = "mapViewToPremiumView"
    }
    
    struct Colors {
        static let primaryColor = "F5F5F5"
        static let secondaryColor = "007AFF"
        static let thirdColor = "EBEBEB"
        static let fourthColor = "F9F4DB"
        static let fifthColor = "A13842"
        /*static let primaryColor = "f9e0ae"EBEBEB
         static let secondaryColor = "fc8621"
         static let thirdColor = "c24914"
         static let fourthColor = "682c0e"*/
    }
    
    struct FStore {
        static let collectionName = "messages"
        static let senderField = "sender"
        static let bodyField = "body"
        static let dateField = "date"
    }

    struct invites {
        struct accountTypes {
            static let freeAccount = "freeAccount"
            static let proAccount = "pro"
        }
    }
    
    struct Entitlements {
        static let professional = "ProfessionalMapServicesSubscriptionGroup"
    }
    
    struct FreeAccountLimitations {
        static let overlayLimit = 10
        static let todoItemLimit = 10
        static let photoLimit = 5
        
        static var toolBarTimer = 120.0
        static var infoPageTimer = 120.0
        static var toDoPageTimer = 120.0// 30.0
        
    }
}
