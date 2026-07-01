struct ConfirmMailRequest: Encodable {
    let userId: String
    let code: String
}

struct ConfirmMailResponse: Decodable {
    let status: String
    let message: String
}

struct ResendConfirmMailRequest: Encodable {
    let email: String
}
