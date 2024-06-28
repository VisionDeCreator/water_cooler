module galliun::attributes {
    // === Imports ===

    use std::string::{String};
    use sui::vec_map::{Self, VecMap};

    // === Structs ===
    
    /// An object an "attributes" field of a `NFT` object.
    public struct Attributes has key, store {
        id: UID,
        fields: VecMap<String, String>,
    }

    /// AttributesCap is used to create an Attributes object.
    public struct AttributesCap has key, store {
        id: UID,
        number: u16,
    }

    // === Public view functions ===

    /// Returns the number of the `Attributes` object.
    public fun number(attributes: &Attributes): u64 {
        attributes.fields.size()
    }

    // === Package functions ===

    /// Create an `Attributes` object with a `AttributesCap`.
    public(package) fun new(
        cap: AttributesCap,
        keys: vector<String>,
        values: vector<String>,
        ctx: &mut TxContext,
    ): Attributes {
        let attributes = Attributes {
            id: object::new(ctx),
            fields: vec_map::from_keys_values(keys, values),
        };

        let AttributesCap { id, number: _ } = cap;
        id.delete();

        attributes
    }

    /// Create `AttributesCap` object.
    public(package) fun create_attributes_cap(
        number: u16,
        ctx: &mut TxContext,
    ): AttributesCap {
        let cap = AttributesCap {
            id: object::new(ctx),
            number: number,
        };

        cap
    }
}
