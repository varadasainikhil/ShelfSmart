struct GroceryProduct : Codable{
    var id : Int?
    var title : String?
    var breadcrumbs : [String]? = [String]()
    var badges : [String]? = [String]()
    var importantBadges : [String]? = [String]()
    var spoonacularScore : Double?
    var image : String?
    var images : [String]? = [String]()
    var generatedText : String?
    var description : String?
    var upc : String?
    var brand : String?
    var ingredientCount : Int?
    var credits : SpoonacularCredit?
}
