module galliun::registry {

    // === Imports ===

    use sui::display;
    use sui::package;
    use sui::table::{Self, Table};
    use galliun::collection;

    public struct REGISTRY has drop {}

    public struct Registry has key {
        id: UID,
        nfts: Table<u16, ID>,
        is_initialized: bool,
        is_frozen: bool,
    }

    // === Constants ===

    const EInvalidNftNumber: u64 = 1;
    const ERegistryNotFrozen: u64 = 4;

    // === Init Function ===

    #[allow(unused_variable, lint(share_owned))]
    fun init(
        otw: REGISTRY,
        ctx: &mut TxContext,
    ) {
        let publisher = package::claim(otw, ctx);

        let registry = Registry {
            id: object::new(ctx),
            nfts: table::new(ctx),
            is_initialized: false,
            is_frozen: false,
        };

        let mut registry_display = display::new<Registry>(&publisher, ctx);
        registry_display.add(b"name".to_string(), b"name".to_string());
        registry_display.add(b"description".to_string(), b"description".to_string());
        registry_display.add(b"image_url".to_string(), b"image_url".to_string());
        registry_display.add(b"is_initialized".to_string(), b"{is_initialized}".to_string());
        registry_display.add(b"is_frozen".to_string(), b"{is_frozen}".to_string());

        transfer::transfer(registry, ctx.sender());

        transfer::public_transfer(registry_display, ctx.sender());
        transfer::public_transfer(publisher, ctx.sender());
    }

    public fun nft_id_from_number(
        number: u16,
        registry: &Registry,
    ): ID {

        assert!(number >= 1 && number <= collection::size(), EInvalidNftNumber);
        assert!(registry.is_frozen == true, ERegistryNotFrozen);

        registry.nfts[number]
    }

    // === Public-Friend Functions ===

    public(package) fun add(
        number: u16,
        nft_id: ID,
        registry: &mut Registry,
    ) {
        registry.nfts.add(number, nft_id);

        if ((registry.nfts.length() as u16) == collection::size()) {
            registry.is_initialized = true;
        };
    }

    public(package) fun is_frozen(
        registry: &Registry,
    ): bool {
        registry.is_frozen
    }

    public(package) fun is_initialized(
        registry: &Registry,
    ): bool {
        registry.is_initialized
    }
}