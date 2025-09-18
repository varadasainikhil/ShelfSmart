struct GroceryProduct : Codable{
    var id : Int?
    var title : String?
    var badges : [String]?
    var importantBadges : [String]?
    var spoonacularScore : Double?
    var image : String?
    var images : [String]?
    var generatedText : String?
    var description : String?
    var upc : String?
    var brand : String?
    var ingredientCount : Int?
    var credits : SpoonacularCredit?
}
