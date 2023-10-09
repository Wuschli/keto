namespace Keto;

public enum Precedence
{
    None,
    Assignment, // =
    Or, // or
    And, // and
    Equality, // == !=
    Comparison, // < > <= =>
    Term, // + -
    Factor, // * /
    Unary, // ! -
    Call, // . ()
    Primary
}