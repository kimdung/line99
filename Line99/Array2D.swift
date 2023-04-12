struct Array2D<T:Codable>: Codable {
    let columns: Int
    let rows: Int
    private var array: [T?]

    init(columns: Int, rows: Int, value: T? = nil) {
        self.columns = columns
        self.rows = rows
        array = Array<T?>(repeating: value, count: rows*columns)
    }

    subscript(column: Int, row: Int) -> T? {
        get {
            return array[row * columns + column]
        }
        set {
            array[row * columns + column] = newValue
        }
    }
}
