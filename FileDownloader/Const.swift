//
//  Const.swift
//
//
//  Created by Alexey Vorobyov
//

import Foundation

enum Const {
    static let news: [URL] = {
        let baseUrlStr = "https://raw.githubusercontent.com/tmp-acc/GTA-V-Radio-Stations/master/common/news/"
        let fileNames: [String] = [
            "mono_news_01.m4a", "mono_news_02.m4a", "mono_news_03.m4a", "mono_news_04.m4a", "mono_news_05.m4a",
            "mono_news_06.m4a", "mono_news_07.m4a", "mono_news_08.m4a", "mono_news_09.m4a", "mono_news_10.m4a",
            "mono_news_100.m4a", "mono_news_101.m4a", "mono_news_102.m4a", "mono_news_103.m4a", "mono_news_104.m4a",
            "mono_news_105.m4a", "mono_news_106.m4a", "mono_news_107.m4a", "mono_news_108.m4a", "mono_news_109.m4a",
            "mono_news_11.m4a", "mono_news_110.m4a", "mono_news_111.m4a", "mono_news_112.m4a", "mono_news_113.m4a",
            "mono_news_114.m4a", "mono_news_115.m4a", "mono_news_116.m4a", "mono_news_117.m4a", "mono_news_118.m4a",
            "mono_news_119.m4a", "mono_news_12.m4a", "mono_news_120.m4a", "mono_news_121.m4a", "mono_news_122.m4a",
            "mono_news_123.m4a", "mono_news_13.m4a", "mono_news_14.m4a", "mono_news_15.m4a", "mono_news_16.m4a",
            "mono_news_17.m4a", "mono_news_18.m4a", "mono_news_19.m4a", "mono_news_20.m4a", "mono_news_21.m4a",
            "mono_news_22.m4a", "mono_news_23.m4a", "mono_news_24.m4a", "mono_news_25.m4a", "mono_news_26.m4a",
            "mono_news_27.m4a", "mono_news_28.m4a", "mono_news_29.m4a", "mono_news_30.m4a", "mono_news_31.m4a",
            "mono_news_32.m4a", "mono_news_33.m4a", "mono_news_34.m4a", "mono_news_35.m4a", "mono_news_36.m4a",
            "mono_news_37.m4a", "mono_news_38.m4a", "mono_news_39.m4a", "mono_news_40.m4a", "mono_news_41.m4a",
            "mono_news_42.m4a", "mono_news_43.m4a", "mono_news_44.m4a", "mono_news_45.m4a", "mono_news_46.m4a",
            "mono_news_47.m4a", "mono_news_48.m4a", "mono_news_49.m4a", "mono_news_50.m4a", "mono_news_51.m4a",
            "mono_news_52.m4a", "mono_news_53.m4a", "mono_news_54.m4a", "mono_news_55.m4a", "mono_news_56.m4a",
            "mono_news_57.m4a", "mono_news_58.m4a", "mono_news_59.m4a", "mono_news_60.m4a", "mono_news_61.m4a",
            "mono_news_62.m4a", "mono_news_63.m4a", "mono_news_64.m4a", "mono_news_81.m4a", "mono_news_82.m4a",
            "mono_news_83.m4a", "mono_news_84.m4a", "mono_news_85.m4a", "mono_news_86.m4a", "mono_news_87.m4a",
            "mono_news_88.m4a", "mono_news_89.m4a", "mono_news_90.m4a", "mono_news_91.m4a", "mono_news_92.m4a",
            "mono_news_93.m4a", "mono_news_94.m4a", "mono_news_95.m4a", "mono_news_96.m4a", "mono_news_97.m4a",
            "mono_news_98.m4a", "mono_news_99.m4a"
        ]
        return fileNames.compactMap { URL(string: baseUrlStr + $0) }
    }()

    static let adverts: [URL] = {
        let baseUrlStr = "https://raw.githubusercontent.com/tmp-acc/GTA-V-Radio-Stations/master/common/adverts/"
        let fileNames: [String] = [
            "ad082_alcoholia.m4a", "mono_ad001_life_invader.m4a", "mono_ad002_righteous_slaughter_nuke.m4a",
            "mono_ad003_righteous_slaughter_russian.m4a", "mono_ad004_righteous_slaughter_levels.m4a",
            "mono_ad005_sa_tourism_board.m4a", "mono_ad006_desert_tourism.m4a", "mono_ad007_sa_water_power.m4a",
            "mono_ad008_up_n_atom.m4a", "mono_ad009_prop_43.m4a", "mono_ad010_toeshoes.m4a",
            "mono_ad011_implant_outsource.m4a", "mono_ad012_donate_your_car.m4a", "mono_ad013_race_to_pluto.m4a",
            "mono_ad014_prop208_dad.m4a", "mono_ad015_prop208_jungle.m4a", "mono_ad016_pisswasser.m4a",
            "mono_ad017_queensbury_boxing.m4a", "mono_ad018_lottery_starving_children.m4a",
            "mono_ad019_lottery_really_addicted.m4a", "mono_ad020_whiz_wirless.m4a",
            "mono_ad021_rectify_holistic.m4a", "mono_ad022_bail_bonds.m4a", "mono_ad023_ovine_human_resources.m4a",
            "mono_ad024_proposition_14.m4a", "mono_ad025_pic_officer.m4a", "mono_ad026_pic_franchise.m4a",
            "mono_ad027_sa_labotomy.m4a", "mono_ad028_darwinian_yoga.m4a", "mono_ad029_gastro_band.m4a",
            "mono_ad030_economic_recovery_group.m4a", "mono_ad031_rehab_island.m4a", "mono_ad032_larrys_rv_sales.m4a",
            "mono_ad033_night_lights.m4a", "mono_ad034_head_shots.m4a", "mono_ad035_electrotoke.m4a",
            "mono_ad036_toilet_cleaner.m4a", "mono_ad037_stop_paying_mortgage.m4a", "mono_ad038_floyds_scrap_metal.m4a",
            "mono_ad039_buddys_trucking.m4a", "mono_ad040_fleeca_interest_fees.m4a", "mono_ad041_fleeca_bedroom.m4a",
            "mono_ad042_shark.m4a", "mono_ad043_smoked_dreams.m4a", "mono_ad044_hipsters_for_hire.m4a",
            "mono_ad045_preservex.m4a", "mono_ad046_dons_country_store.m4a", "mono_ad047_proposition_45.m4a",
            "mono_ad048_windsor_immigrant.m4a", "mono_ad049_windsor_swinger_grotto.m4a",
            "mono_ad050_cuckold_theraphy.m4a", "mono_ad051_digifarm_daughter.m4a",
            "mono_ad052_digifarm_other_games.m4a", "mono_ad053_blaine_county_bank.m4a", "mono_ad054_lombank.m4a",
            "mono_ad055_hitting_kids_works_wonders.m4a", "mono_ad056_vinewood_health.m4a",
            "mono_ad057_benders_wanker.m4a", "mono_ad058_benders_pies.m4a", "mono_ad059_youtool.m4a",
            "mono_ad060_amunation_gardening.m4a", "mono_ad061_amunation_apocolypse.m4a", "mono_ad062_flow_water.m4a",
            "mono_ad063_sex_addiction_opportunity.m4a", "mono_ad064_serious_cougar.m4a",
            "mono_ad065_cloud_computing.m4a", "mono_ad067_pride_prej_grain_alcohol.m4a",
            "mono_ad068_pride_prej_tornado.m4a", "mono_ad069_hitting_kids_pot.m4a",
            "mono_ad070_hammerstein_faust.m4a", "mono_ad071_grain_of_truth.m4a", "mono_ad072_fly_us_choice.m4a",
            "mono_ad073_fly_us_drunk.m4a", "mono_ad074_fly_us_planes.m4a", "mono_ad075_refinance_ls_commerce.m4a",
            "mono_ad076_rebranding_jerking.m4a", "mono_ad077_rebranding_abyss.m4a",
            "mono_ad078_sex_addict_drowning.m4a", "mono_ad079_sex_addict_train.m4a", "mono_ad080_sex_manopause.m4a",
            "mono_ad081_mma.m4a", "mono_ad083_egochaser.m4a", "mono_ad084_chains_intmacy_throb.m4a",
            "mono_ad085_chains_intmacy_diamonds.m4a", "mono_ad086_bravado_farms.m4a",
            "mono_ad087_bravado_cruise_control.m4a", "mono_ad088_sa_flight_school.m4a",
            "mono_ad089_crevis_nature_revised.m4a", "mono_ad090_crevis_everest.m4a", "mono_ad091_epsilon_antartica.m4a",
            "mono_ad092_epsilon_famous_people.m4a", "mono_ad093_sex_addiction_victim.m4a", "mono_ad094_pontius.m4a",
            "mono_ad095_sue_murry.m4a", "mono_ad096_jock_cranley1.m4a", "mono_ad097_jock_cranley2.m4a"
        ]
        return fileNames.compactMap { URL(string: baseUrlStr + $0) }
    }()

    static let largeFiles: [URL] = {
        let baseUrlStr = "https://raw.githubusercontent.com/tmp-acc/GTA-V-Radio-Stations/master/"
        let fileNames: [String] = [
            "radio_08_mexican/mex_final_mix_32.m4a",
            "radio_13_jazz/wwfm_p1.m4a",
            "radio_13_jazz/wwfm_p2.m4a",
            "radio_05_talk_01/mono_chakra_attack_part_1.m4a"
        ]
        return fileNames.compactMap { URL(string: baseUrlStr + $0) }
    }()
}
