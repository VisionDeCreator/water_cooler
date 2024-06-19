module galliun::attributes {

    // === Imports ===

    use std::string::{String};
    use sui::dynamic_field;

    use sui::vec_map::{VecMap};

    // === Friends ===

    //use galliun::water_cooler;

    // === Structs ===
    
    /// An object that holds a `AttributesData` object,
    /// assigned to the "attributes" field of a `NFT` object.
    public struct Attributes has key, store {
        id: UID,
        number: u16,
        fields: AttributesData
    }

    /// An object that holds the NFTs attributes.
    public struct AttributesData has store {
        map: VecMap<String, String>,
    }

    public struct CreateAttributesCap has key, store {
        id: UID,
        number: u16,
    }

    /// Create an `Attributes` object with a `CreateAttributesCap`.
    public(package) fun new(
        cap: CreateAttributesCap,
        number: u16,
        attributes: VecMap<String, String>,
        ctx: &mut TxContext,
    ): Attributes {
        let attributes_data = AttributesData {
            map: attributes
        };

        let attributes = Attributes {
            id: object::new(ctx),
            number,
            fields: attributes_data,
        };
        let CreateAttributesCap { id, number: _ } = cap;
        id.delete();

        attributes
    }

    /// Create a `CreateAttributesCap`.
    public(package) fun create_attributes_cap(
        number: u16,
        ctx: &mut TxContext,
    ): CreateAttributesCap {
        let cap = CreateAttributesCap {
            id: object::new(ctx),
            number: number,
        };

        cap
    }

    // add dynamic field "AttributesData"
    public fun add_attributes_data(attributes: &mut Attributes, attributes_data: AttributesData, key: u64) {
        dynamic_field::add(&mut attributes.id, key, attributes_data);
    }

    /// Returns the number of the `Attributes` object.
    public(package) fun number(
        attributes: &Attributes,
    ): u16 {
        attributes.number
    }
}