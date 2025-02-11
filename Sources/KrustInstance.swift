/// Runtime representation of an instace of a Krust class
final class KrustInstance: CustomStringConvertible {
    private let krustClass: KrustClass

    var description: String { "\(krustClass.name) instance" }

    init(krustClass: KrustClass) {
        self.krustClass = krustClass
    }
}
