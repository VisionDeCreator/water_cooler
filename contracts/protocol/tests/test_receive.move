#[test_only]
module galliun::test_recieve {
    // === Imports ===
    use sui::{
        test_scenario::{Self as ts, next_tx},
        coin::{Self},
        sui::SUI,
        transfer::{Self, Receiving},
        test_utils::{assert_eq},
        kiosk::{Self, Kiosk, KioskOwnerCap},
        transfer_policy::{Self as tp, TransferPolicy, TransferPolicyCap}
    };
    use std::string::{Self, String};
    use galliun::{
        helpers::{init_test_helper},
        water_cooler::{Self, WaterCooler, WaterCoolerAdminCap},
        mizu_nft::{Self, MizuNFT},
        cooler_factory::{Self, CoolerFactory, FactoryOwnerCap},
        mint::{Self, Mint, MintAdminCap, MintSettings, MintWarehouse, WhitelistTicket, OriginalGangsterTicket},
        attributes::{Self, Attributes},
        receive::{Self, ReceiveSettings, ReturnKioskOwnerCapPromise}
    };

    // === Constants ===
    const ADMIN: address = @0xA;
    const TEST_ADDRESS1: address = @0xB;
    // const TEST_ADDRESS2: address = @0xC;

    // === Test functions ===
    #[test]
    public fun test_receive() {

        let mut scenario_test = init_test_helper();
        let scenario = &mut scenario_test;
        
        // User has to buy water_cooler from cooler_factory share object. 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let mut cooler_factory = ts::take_shared<CoolerFactory>(scenario);
            let coin_ = coin::mint_for_testing<SUI>(100, ts::ctx(scenario));
            
            let name = b"watercoolername".to_string();
            let description = b"some desc".to_string();
            let image_url = b"https://media.nfts.photos/nft.jpg".to_string();
            let supply = 150;

            cooler_factory::buy_water_cooler(
                &mut cooler_factory,
                coin_,
                name,
                description,
                image_url,
                supply,
                TEST_ADDRESS1,
                ts::ctx(scenario)
            );
            // check the balance 
            assert_eq(cooler_factory.get_balance(), 100);

            ts::return_shared(cooler_factory);
        };

        next_tx(scenario, ADMIN);
        {
            let mut cooler_factory = ts::take_shared<CoolerFactory>(scenario);
            let cap = ts::take_from_sender<FactoryOwnerCap>(scenario);
            // admin can claim fee which is 100 
            let coin_ = cooler_factory::claim_fee(&cap, &mut cooler_factory, ts::ctx(scenario));
            // it should be equal to 100
            assert_eq(coin_.value(), 100);
            // transfer it to admin address 
            transfer::public_transfer(coin_, ADMIN);
     
            ts::return_to_sender(scenario, cap);
            ts::return_shared(cooler_factory);
        };
        // set the new fee 
        next_tx(scenario, ADMIN);
        {
            let mut cooler_factory = ts::take_shared<CoolerFactory>(scenario);
            let cap = ts::take_from_sender<FactoryOwnerCap>(scenario);
          
            let new_fee_rate: u64 = 90;
            cooler_factory::update_fee(&cap, &mut cooler_factory, new_fee_rate);
            assert_eq(cooler_factory.get_fee(), new_fee_rate);

            ts::return_to_sender(scenario, cap);
            ts::return_shared(cooler_factory);
        };

        // init WaterCooler. the number count to 1. So it is working. 
        ts::next_tx(scenario, TEST_ADDRESS1);
        {
            let mut water_cooler = ts::take_shared<WaterCooler>(scenario);
            let water_cooler_admin_cap = ts::take_from_sender<WaterCoolerAdminCap>(scenario);

            water_cooler::initialize_water_cooler(&water_cooler_admin_cap, &mut water_cooler, ts::ctx(scenario));

            ts::return_shared(water_cooler);
            ts::return_to_sender(scenario, water_cooler_admin_cap);
        };
        // check that does user has MizuNFT ?
        ts::next_tx(scenario, TEST_ADDRESS1);
        {
            let mut nft = ts::take_from_sender<MizuNFT>(scenario);
            let nft_id = mizu_nft::get_id(&nft);
            let receiver = ts::receiving_ticket_by_id<KioskOwnerCap>(nft_id);

            let (cap, promise) = receive::receive_kiosk_owner_cap(&mut nft, receiver);
            
            receive::return_kiosk_owner_cap(cap, promise);

            ts::return_to_sender(scenario, nft);
        };

            ts::end(scenario_test);
    }
}
