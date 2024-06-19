#[test_only]
module galliun::water_cooler_tests {
    use sui::test_scenario;
    use sui::coin;
    use sui::sui::SUI;
    use sui::kiosk::{Self, Kiosk, KioskOwnerCap};
    use sui::transfer_policy::{Self, TransferPolicy};
    use sui::package::{Self, Publisher};
    use sui::vec_map::{Self, VecMap};
    use std::string::{String};

    use galliun::water_cooler::{Self as water_cooler, WaterCooler, WaterCoolerAdminCap, MizuNFT};
    use galliun::mint::{Self as mint, Mint, MintSettings, MintWarehouse, MintAdminCap, WhitelistTicket, OriginalGangsterTicket};
    use galliun::attributes::{Self as attributes, Attributes, CreateAttributesCap};

    // === Users ===
    const USER: address = @0xab;

    // === Error ===
    const EYouDontOwnTheOBJ: u64 = 4;
    
  #[test]
    fun test_water_cooler() {

        let mut scenario_val = test_scenario::begin(USER);
        let scenario = &mut scenario_val;

        // === Test Init Water Cooler===
        test_scenario::next_tx(scenario, USER);
        {
            water_cooler::init_for_testing(test_scenario::ctx(scenario));
            mint::init_for_testing(test_scenario::ctx(scenario));
        };

        // === Test Create Water Cooler ===
        test_scenario::next_tx(scenario, USER);
        {
            let name = b"watercoolername".to_string();
            let description = b"some desc".to_string();
            let image_url = b"https://media.nfts.photos/nft.jpg".to_string();
            let size = 150;

            water_cooler::createWaterCooler(name, description, image_url, size, USER, test_scenario::ctx(scenario));
        };
        test_scenario::next_tx(scenario, USER);
        {
            assert!(test_scenario::has_most_recent_for_sender<WaterCooler>(scenario), 0);
        };

        // === Test Admin Water Cooler Init ===
        test_scenario::next_tx(scenario, USER);
        {
            let mut water_cooler = test_scenario::take_from_sender<WaterCooler>(scenario);
            let water_cooler_admin_cap = test_scenario::take_from_sender<WaterCoolerAdminCap>(scenario);

            water_cooler::admin_initialize_water_cooler(&water_cooler_admin_cap, &mut water_cooler, test_scenario::ctx(scenario));

            test_scenario::return_to_sender(scenario, water_cooler);
            test_scenario::return_to_sender(scenario, water_cooler_admin_cap);
        };
        test_scenario::next_tx(scenario, USER);
        {
            let water_cooler = test_scenario::take_from_sender<WaterCooler>(scenario);

            // Check Nft Created
            assert!(test_scenario::has_most_recent_for_sender<MizuNFT>(scenario), 0);
            assert!(water_cooler.is_initialized() == true, 0);     

            test_scenario::return_to_sender(scenario, water_cooler);
        };

        // === Test Create Mint Distributer ===
        test_scenario::next_tx(scenario, USER);
        {
            mint::create_mint_distributer(test_scenario::ctx(scenario));
            mint::create_wl_distributer(test_scenario::ctx(scenario));
            mint::create_og_distributer(test_scenario::ctx(scenario));
        };

        // === Test Public Mint ===
        test_scenario::next_tx(scenario, USER);
        {
            let mut warehouse = test_scenario::take_shared<MintWarehouse>(scenario);
            let mut settings = test_scenario::take_shared<MintSettings>(scenario);
            let mint_admin_cap = test_scenario::take_from_sender<MintAdminCap>(scenario);
            let public_payment = coin::mint_for_testing<SUI>(10, test_scenario::ctx(scenario));
            let wl_payment = coin::mint_for_testing<SUI>(10, test_scenario::ctx(scenario));
            let og_payment = coin::mint_for_testing<SUI>(10, test_scenario::ctx(scenario));
            let water_cooler = test_scenario::take_from_sender<WaterCooler>(scenario);
            let public_nfts = test_scenario::take_from_sender<MizuNFT>(scenario);
            let wl_nfts = test_scenario::take_from_sender<MizuNFT>(scenario);
            let og_nfts = test_scenario::take_from_sender<MizuNFT>(scenario);
            let whitelist_ticket = test_scenario::take_from_sender<WhitelistTicket>(scenario);
            let og_ticket = test_scenario::take_from_sender<OriginalGangsterTicket>(scenario);       

            // set mint status
            mint::admin_set_mint_status(&mint_admin_cap, 1, &mut settings, test_scenario::ctx(scenario));

            // test public mint
            // add nft to warehouse 
            mint::admin_add_to_mint_warehouse(&mint_admin_cap, &water_cooler, vector[public_nfts], &mut warehouse, test_scenario::ctx(scenario));

            // set mint price at 10 sui
            mint::admin_set_mint_price(&mint_admin_cap, 10, &mut settings, test_scenario::ctx(scenario));
            // test public mint at 10sui payment
            mint::public_mint(public_payment, &mut warehouse, &settings, test_scenario::ctx(scenario));

            // test wl mint
            // add nft to warehouse 
            mint::admin_add_to_mint_warehouse(&mint_admin_cap, &water_cooler, vector[wl_nfts], &mut warehouse, test_scenario::ctx(scenario));

            // test wl mint at 10sui payment
            mint::whitelist_mint(whitelist_ticket, wl_payment, &mut warehouse, &settings, test_scenario::ctx(scenario));

            // test og mint
            // add nft to warehouse 
            mint::admin_add_to_mint_warehouse(&mint_admin_cap, &water_cooler, vector[og_nfts], &mut warehouse, test_scenario::ctx(scenario));

            // test og mint at 10sui payment
            mint::og_mint(og_ticket, og_payment, &mut warehouse, &settings, test_scenario::ctx(scenario));
        
            test_scenario::return_shared(settings);
            test_scenario::return_to_sender(scenario, mint_admin_cap);
            test_scenario::return_to_sender(scenario, water_cooler);
            test_scenario::return_shared(warehouse);   
        };

        // Proof of Minting
        test_scenario::next_tx(scenario, USER);
        {   
            let mut warehouse = test_scenario::take_shared<MintWarehouse>(scenario);
            let mut mint = test_scenario::take_shared<Mint>(scenario);

            // check that warehouse is empty
            assert!(mint::warehouse_length(&mut warehouse) == 0, 0);
            // check that nft minted by USER
            assert!(mint::nft_minted_by(&mut mint) == USER, 0);

            test_scenario::return_shared(mint);
            test_scenario::return_shared(warehouse);  
        };

        // Create kiosk for testing
        test_scenario::next_tx(scenario, USER);
        {
            
            let (kiosk, cap) = kiosk::new(test_scenario::ctx(scenario));
            transfer::public_share_object(kiosk);
            transfer::public_transfer(cap, USER);
        };

        // Test Attributes
        test_scenario::next_tx(scenario, USER);
        {
            let create_attributes_cap = attributes::create_attributes_cap(2, test_scenario::ctx(scenario));
            transfer::public_transfer(create_attributes_cap, USER);
        };      
        test_scenario::next_tx(scenario, USER);
        {   
            let mut attributes = vec_map::empty();
            vec_map::insert(&mut attributes, b"Unique".to_string(), b"Adaptability".to_string());
            let create_attributes_cap = test_scenario::take_from_sender<CreateAttributesCap>(scenario);

            let attributes = attributes::new(create_attributes_cap, 2, attributes, test_scenario::ctx(scenario));
            transfer::public_transfer(attributes, USER);
        };

        // Test Claim
        test_scenario::next_tx(scenario, USER);
        {   
            let water_cooler = test_scenario::take_from_sender<WaterCooler>(scenario);
            let mut mint = test_scenario::take_shared<Mint>(scenario);
            let mut kiosk = test_scenario::take_shared<Kiosk>(scenario);
            let kiosk_owner_cap = test_scenario::take_from_address<KioskOwnerCap>(scenario, USER);
            let transfer_policy = test_scenario::take_shared<TransferPolicy<MizuNFT>>(scenario);
            let mint_admin_cap = test_scenario::take_from_sender<MintAdminCap>(scenario);
            let attributes = test_scenario::take_from_sender<Attributes>(scenario);
            let image = b"nft.jpg".to_string();

            mint::admin_reveal_mint(&mint_admin_cap, &mut mint, attributes, image);
            mint::claim_mint(&water_cooler, mint, &mut kiosk, &kiosk_owner_cap, &transfer_policy, test_scenario::ctx(scenario));

            // check kiosk items = 1 item
            assert!(mint::kiosk_items(&mut kiosk) == 1, 0);

            test_scenario::return_to_sender(scenario, water_cooler);
            test_scenario::return_to_sender(scenario, kiosk_owner_cap);
            test_scenario::return_to_sender(scenario, mint_admin_cap);
            test_scenario::return_shared(transfer_policy);
            test_scenario::return_shared(kiosk);
        };

        test_scenario::end(scenario_val);
    }
}