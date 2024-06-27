module galliun::receive {

    // === Imports ===

    use std::type_name::{Self, TypeName};

    use sui::coin::Coin;
    use sui::event;
    use sui::kiosk::{KioskOwnerCap};
    use sui::transfer::Receiving;

    use galliun::cooler_factory::{FactoryOwnerCap};
    use galliun::mizu_nft::{MizuNFT};

    use CoolerFactoryToken::usdc::USDC;

    // === Errors ===

    const EIncorrectUSDCFeeAmount: u64 = 1;
    const EInvalidReceiveType: u64 = 2;
    const EInvalidKioskOwnerCapForPromise: u64 = 3;
    const EInvalidKioskOwnerCapForPrimeMachin: u64 = 4;

    // === Constants ===

    const DEFAULT_RECEIVE_FEE: u64 = 100; // 100 USDC

    // === Structs ===

    public struct RECEIVE has drop {}

    public struct ReceiveSettings has key {
        id: UID,
        // USDC fee for receiving an object.
        fee: u64,
    }

    /// A hot potato struct that forces the caller to return the KioskOwnerCap back
    /// to the Prime Machin before completing a PTB.
    public struct ReturnKioskOwnerCapPromise {
        pfp_id: ID,
        kiosk_owner_cap_id: ID,
    }

    // === Events ===

    public struct ObjectReceivedEvent has copy, drop {
        pfp_id: ID,
        received_object_id: ID,
        received_object_type: TypeName,
    }

    fun init(
        _otw: RECEIVE,
        ctx: &mut TxContext,
    ) {
        let settings = ReceiveSettings {
            id: object::new(ctx),
            fee: DEFAULT_RECEIVE_FEE,
        };

        transfer::share_object(settings);
    }

    /// A catch-all function to receive objects that have been sent to the Prime Machin.
    /// This function can be used to receive any type except KioskOwnerCap and USDC.
    public fun receive<T: key + store>(
        pfp: &mut MizuNFT,
        obj_to_receive: Receiving<T>,
        fee: Coin<USDC>,
        settings: &ReceiveSettings,
    ): T {
        // Assert catch-all receive function is not used to receive KioskOwnerCap or USDC.
        assert!(type_name::get<T>() != type_name::get<KioskOwnerCap>(), EInvalidReceiveType);
        assert!(type_name::get<T>() != type_name::get<USDC>(), EInvalidReceiveType);

        // Assert USDC fee is the correct amount.
        assert!(fee.value() == settings.fee, EIncorrectUSDCFeeAmount);

        // Transfer the fee to SM.
        transfer::public_transfer(fee, @treasury);

        // Receive the object.
        let received_object = transfer::public_receive(pfp.uid_mut(), obj_to_receive);

        event::emit(
            ObjectReceivedEvent {
                pfp_id: pfp.get_id(),
                received_object_id: object::id(&received_object),
                received_object_type: type_name::get<T>(),
            }
        );

        received_object
    }

    /// A function for receiving USDC coin objects that have been sent to the Prime Machin.
    /// This function bypasses the USDC fee on the catch-all function.
    public fun receive_USDC(
        pfp: &mut MizuNFT,
        coin_: Receiving<Coin<USDC>>,
    ): Coin<USDC> {
        transfer::public_receive(pfp.uid_mut(), coin_)
    }

    /// A function for receiving the Prime Machin's KioskOwnerCap.
    /// This function returns the KioskOwnerCap as well as a ReturnKioskOwnerCapPromise
    /// to return it back to the Prime Machin. In order for a PTB to execute successfully,
    /// the KioskOwnerCap and ReturnKioskOwnerCapPromise must be passed to return_kiosk_owner_cap().
    public fun receive_kiosk_owner_cap(
        pfp: &mut MizuNFT,
        kiosk_owner_cap_to_receive: Receiving<KioskOwnerCap>,
    ): (KioskOwnerCap, ReturnKioskOwnerCapPromise) {
        // Assert the KioskOwnerCap to receive matches the KioskOwnerCap assigned to the Prime Machin.
        assert!(transfer::receiving_object_id(&kiosk_owner_cap_to_receive) == pfp.kiosk_owner_cap_id(), EInvalidKioskOwnerCapForPrimeMachin);

        let kiosk_owner_cap = transfer::public_receive(pfp.uid_mut(), kiosk_owner_cap_to_receive);

        let promise = ReturnKioskOwnerCapPromise {
            pfp_id: pfp.get_id(),
            kiosk_owner_cap_id: object::id(&kiosk_owner_cap),
        };

        (kiosk_owner_cap, promise)
    }

    /// Return the KioskOwnerCap back to the Prime Machin, and destroy the ReturnKioskOwnerCapPromise.
    public fun return_kiosk_owner_cap(
        kiosk_owner_cap: KioskOwnerCap,
        promise: ReturnKioskOwnerCapPromise,
    ) {
        assert!(promise.kiosk_owner_cap_id == object::id(&kiosk_owner_cap), EInvalidKioskOwnerCapForPromise);
        transfer::public_transfer(kiosk_owner_cap, promise.pfp_id.to_address());

        let ReturnKioskOwnerCapPromise { pfp_id: _, kiosk_owner_cap_id: _ } = promise;
    }

    // === Admin Functions ===

    /// Set the USDC fee associated with catch-all receives.
    public fun admin_set_receive_fee(
        _: &FactoryOwnerCap,
        settings: &mut ReceiveSettings,
        amount: u64,
    ) {
        settings.fee= amount
    }

    // === Test Functions ===

    #[test_only]
    public fun init_test_receive(ctx: &mut TxContext) {
        init(RECEIVE {}, ctx);
    }
}
