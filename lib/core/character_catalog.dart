String titleCaseFolder(String value) => value
    .split(RegExp(r'\s+'))
    .where((part) => part.isNotEmpty)
    .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
    .join(' ');

enum ZzzAttribute {
  none,
  physical,
  fire,
  ice,
  electric,
  ether,
  wind,
  frost,
  lumiflux,
  honedEdge,
  auricInk,
}

class ZzzCharacterInfo {
  final String name;
  final ZzzAttribute attribute;

  const ZzzCharacterInfo(this.name, this.attribute);
}

/// Thông tin hiển thị của nhân vật. Attribute được giữ riêng với tên folder
/// để đổi tên skin hoặc folder không làm mất dữ liệu nền của nhân vật.
const zzzCharacterCatalog = <String, ZzzCharacterInfo>{
  'Alice Thymefield': ZzzCharacterInfo(
    'Alice Thymefield',
    ZzzAttribute.physical,
  ),
  'Anby Demara': ZzzCharacterInfo('Anby Demara', ZzzAttribute.electric),
  'Anton Ivanov': ZzzCharacterInfo('Anton Ivanov', ZzzAttribute.electric),
  'Aria': ZzzCharacterInfo('Aria', ZzzAttribute.ether),
  'Astra Yao': ZzzCharacterInfo('Astra Yao', ZzzAttribute.ether),
  'Asaba Harumasa': ZzzCharacterInfo('Asaba Harumasa', ZzzAttribute.electric),
  'Banyue': ZzzCharacterInfo('Banyue', ZzzAttribute.fire),
  'Belle': ZzzCharacterInfo('Belle', ZzzAttribute.none),
  'Ben Bigger': ZzzCharacterInfo('Ben Bigger', ZzzAttribute.fire),
  'Billy Kid': ZzzCharacterInfo('Billy Kid', ZzzAttribute.physical),
  'Burnice White': ZzzCharacterInfo('Burnice White', ZzzAttribute.fire),
  'Caesar King': ZzzCharacterInfo('Caesar King', ZzzAttribute.physical),
  'Cissia': ZzzCharacterInfo('Cissia', ZzzAttribute.electric),
  'Claret Flint': ZzzCharacterInfo('Claret Flint', ZzzAttribute.electric),
  'Corin Wickes': ZzzCharacterInfo('Corin Wickes', ZzzAttribute.physical),
  'Dialyn': ZzzCharacterInfo('Dialyn', ZzzAttribute.physical),
  'Ellen Joe': ZzzCharacterInfo('Ellen Joe', ZzzAttribute.ice),
  'Evelyn Chevalier': ZzzCharacterInfo('Evelyn Chevalier', ZzzAttribute.fire),
  'Grace Howard': ZzzCharacterInfo('Grace Howard', ZzzAttribute.electric),
  'Hugo Vlad': ZzzCharacterInfo('Hugo Vlad', ZzzAttribute.ice),
  'Jane Doe': ZzzCharacterInfo('Jane Doe', ZzzAttribute.physical),
  'Ju Fufu': ZzzCharacterInfo('Ju Fufu', ZzzAttribute.fire),
  'Koleda Belobog': ZzzCharacterInfo('Koleda Belobog', ZzzAttribute.fire),
  'Komano Manato': ZzzCharacterInfo('Komano Manato', ZzzAttribute.fire),
  'Lighter': ZzzCharacterInfo('Lighter', ZzzAttribute.fire),
  'Lucia': ZzzCharacterInfo('Lucia', ZzzAttribute.ether),
  'Lucy': ZzzCharacterInfo('Lucy', ZzzAttribute.physical),
  'Lycaon': ZzzCharacterInfo('Lycaon', ZzzAttribute.ice),
  'Miyabi': ZzzCharacterInfo('Miyabi', ZzzAttribute.frost),
  'Nangong Yu': ZzzCharacterInfo('Nangong Yu', ZzzAttribute.ether),
  'Nekomata': ZzzCharacterInfo('Nekomata', ZzzAttribute.physical),
  'Nicole Demara': ZzzCharacterInfo('Nicole Demara', ZzzAttribute.ether),
  'Norma Hollowell': ZzzCharacterInfo('Norma Hollowell', ZzzAttribute.fire),
  'Orphie and Magus': ZzzCharacterInfo('Orphie and Magus', ZzzAttribute.fire),
  'Pan Yinhu': ZzzCharacterInfo('Pan Yinhu', ZzzAttribute.physical),
  'Phoenix Reffaella': ZzzCharacterInfo('Phoenix Reffaella', ZzzAttribute.fire),
  'Piper Wheel': ZzzCharacterInfo('Piper Wheel', ZzzAttribute.physical),
  'Promeia': ZzzCharacterInfo('Promeia', ZzzAttribute.ice),
  'Pulchra': ZzzCharacterInfo('Pulchra', ZzzAttribute.physical),
  'Pyrois': ZzzCharacterInfo('Pyrois', ZzzAttribute.ether),
  'Qingyi': ZzzCharacterInfo('Qingyi', ZzzAttribute.electric),
  'Remielle Dan': ZzzCharacterInfo('Remielle Dan', ZzzAttribute.lumiflux),
  'Rina': ZzzCharacterInfo('Rina', ZzzAttribute.electric),
  'Roxy Ifrita Pryce': ZzzCharacterInfo('Roxy Ifrita Pryce', ZzzAttribute.wind),
  'Seed': ZzzCharacterInfo('Seed', ZzzAttribute.electric),
  'Severian Lowell': ZzzCharacterInfo('Severian Lowell', ZzzAttribute.wind),
  'Seth Lowell': ZzzCharacterInfo('Seth Lowell', ZzzAttribute.electric),
  'Soldier 0 - Anby': ZzzCharacterInfo(
    'Soldier 0 - Anby',
    ZzzAttribute.electric,
  ),
  'Soldier 11': ZzzCharacterInfo('Soldier 11', ZzzAttribute.fire),
  'Soukaku': ZzzCharacterInfo('Soukaku', ZzzAttribute.ice),
  'Sigrid de L\'Azur': ZzzCharacterInfo('Sigrid de L\'Azur', ZzzAttribute.ice),
  'Starlight - Billy Kid': ZzzCharacterInfo(
    'Starlight - Billy Kid',
    ZzzAttribute.physical,
  ),
  'Sunna': ZzzCharacterInfo('Sunna', ZzzAttribute.physical),
  'Trigger': ZzzCharacterInfo('Trigger', ZzzAttribute.electric),
  'Ukinami Yuzuha': ZzzCharacterInfo('Ukinami Yuzuha', ZzzAttribute.physical),
  'Velina Airgid': ZzzCharacterInfo('Velina Airgid', ZzzAttribute.wind),
  'Vivian': ZzzCharacterInfo('Vivian', ZzzAttribute.ether),
  'Wise': ZzzCharacterInfo('Wise', ZzzAttribute.none),
  'Yanagi': ZzzCharacterInfo('Yanagi', ZzzAttribute.electric),
  'Ye Shunguang': ZzzCharacterInfo('Ye Shunguang', ZzzAttribute.honedEdge),
  'Yidhari Murphy': ZzzCharacterInfo('Yidhari Murphy', ZzzAttribute.ice),
  'Yixuan': ZzzCharacterInfo('Yixuan', ZzzAttribute.auricInk),
  'Zhao': ZzzCharacterInfo('Zhao', ZzzAttribute.ice),
  'Zhu Yuan': ZzzCharacterInfo('Zhu Yuan', ZzzAttribute.ether),
};

ZzzCharacterInfo? zzzCharacterInfoFor(String name) {
  final lower = name.toLowerCase();
  for (final entry in zzzCharacterCatalog.entries) {
    if (entry.key.toLowerCase() == lower) return entry.value;
  }
  return null;
}

/// Tên các nhân vật ZZZ dùng để tạo cấu trúc folder ban đầu.
/// Khi game có nhân vật mới, chỉ cần bổ sung tên vào danh sách này.
const zzzCharacterFolders = <String>[
  'Alice Thymefield',
  'Anby Demara',
  'Anton Ivanov',
  'Aria',
  'Astra Yao',
  'Asaba Harumasa',
  'Banyue',
  'Belle',
  'Ben Bigger',
  'Billy Kid',
  'Burnice White',
  'Caesar King',
  'Cissia',
  'Claret Flint',
  'Corin Wickes',
  'Dialyn',
  'Ellen Joe',
  'Evelyn Chevalier',
  'Grace Howard',
  'Hugo Vlad',
  'Jane Doe',
  'Ju Fufu',
  'Koleda Belobog',
  'Komano Manato',
  'Lighter',
  'Lucia',
  'Lucy',
  'Lycaon',
  'Miyabi',
  'Nangong Yu',
  'Nekomata',
  'Nicole Demara',
  'Norma Hollowell',
  'Orphie and Magus',
  'Pan Yinhu',
  'Phoenix Reffaella',
  'Piper Wheel',
  'Promeia',
  'Pulchra',
  'Pyrois',
  'Qingyi',
  'Remielle Dan',
  'Rina',
  'Roxy Ifrita Pryce',
  'Seed',
  'Severian Lowell',
  'Seth Lowell',
  'Soldier 0 - Anby',
  'Soldier 11',
  'Soukaku',
  'Sigrid de L\'Azur',
  'Starlight - Billy Kid',
  'Sunna',
  'Trigger',
  'Ukinami Yuzuha',
  'Velina Airgid',
  'Vivian',
  'Wise',
  'Yanagi',
  'Ye Shunguang',
  'Yidhari Murphy',
  'Yixuan',
  'Zhao',
  'Zhu Yuan',
];

/// Trang phục bổ sung theo danh sách Agent Outfits trên ZZZ Wiki.
/// Tên thư mục: `Tên nhân vật - Tên trang phục`.
const zzzSkinFolders = <String, List<String>>{
  'Alice Thymefield': ['Sea of Thyme'],
  'Aria': ['Cuteness Loading', 'Discordant Note'],
  'Astra Yao': ['Chandelier'],
  'Belle': ['Delicate Sunlight', 'Summer Skies', 'Brilliance of Stars'],
  'Ellen Joe': ['On Campus'],
  'Jane Doe': ['Nocturne of Light'],
  'Komano Manato': ['White Heart Silhouette'],
  'Lucy': ['Princess on Holiday'],
  'Miyabi': ['Dignified Blossom'],
  'Nangong Yu': ['Heartfelt Support', "Rhapsody's Muse"],
  'Nicole Demara': ['Cunning Cutie'],
  'Pan Yinhu': ['Culinary Jewel'],
  'Phoenix Reffaella': ['Daydream Complex', 'The Illness Called Life'],
  'Remielle Dan': ['Moonlight Whispers', 'Seashade Pas Seul'],
  'Sigrid de L\'Azur': ['Majestic Wavechaser'],
  'Sunna': ['Afternoon Tea Break', 'Delusions in Business'],
  'Ukinami Yuzuha': ['Tanuki in Broad Daylight'],
  'Velina Airgid': ['Shade of Leisure'],
  'Vivian': ['Iris of the Shore'],
  'Wise': ['Soaring Crane', 'Peaceful Waves', 'Oath of Skies'],
  'Ye Shunguang': ['Touch of Dawnlight'],
  'Yixuan': ['Trails of Ink'],
};

const zzzSkinAvatarAssets = <String, String>{
  'Alice Thymefield - Sea of Thyme':
      'assets/characters/alice_thymefield/sea_of_thyme.png',
  'Aria - Cuteness Loading': 'assets/characters/aria/cuteness_loading.png',
  'Aria - Discordant Note': 'assets/characters/aria/discordant_note.png',
  'Astra Yao - Chandelier': 'assets/characters/astra_yao/chandelier.webp',
  'Belle - Delicate Sunlight': 'assets/characters/belle/delicate_sunlight.webp',
  'Belle - Summer Skies': 'assets/characters/belle/summer_skies.webp',
  'Belle - Brilliance of Stars':
      'assets/characters/belle/brilliance_of_stars.webp',
  'Ellen Joe - On Campus': 'assets/characters/ellen_joe/on_campus.webp',
  'Jane Doe - Nocturne of Light':
      'assets/characters/jane_doe/nocturne_of_light.webp',
  'Komano Manato - White Heart Silhouette':
      'assets/characters/komano_manato/white_heart_silhouette.png',
  'Lucy - Princess on Holiday':
      'assets/characters/lucy/princess_on_holiday.webp',
  'Miyabi - Dignified Blossom':
      'assets/characters/miyabi/dignified_blossom.webp',
  'Nangong Yu - Heartfelt Support':
      'assets/characters/nangong_yu/heartfelt_support.png',
  "Nangong Yu - Rhapsody's Muse":
      'assets/characters/nangong_yu/rhapsodys_muse.png',
  'Nicole Demara - Cunning Cutie':
      'assets/characters/nicole_demara/cunning_cutie.webp',
  'Pan Yinhu - Culinary Jewel':
      'assets/characters/pan_yinhu/culinary_jewel.webp',
  'Phoenix Reffaella - Daydream Complex':
      'assets/characters/phoenix_reffaella/daydream_complex.png',
  'Phoenix Reffaella - The Illness Called Life':
      'assets/characters/phoenix_reffaella/the_illness_called_life.png',
  'Remielle Dan - Moonlight Whispers':
      'assets/characters/remielle_dan/moonlight_whispers.png',
  'Remielle Dan - Seashade Pas Seul':
      'assets/characters/remielle_dan/seashade_pas_seul.png',
  'Sigrid de L\'Azur - Majestic Wavechaser':
      'assets/characters/sigrid_de_l_azur/majestic_wavechaser.png',
  'Sunna - Afternoon Tea Break':
      'assets/characters/sunna/afternoon_tea_break.png',
  'Sunna - Delusions in Business':
      'assets/characters/sunna/delusions_in_business.png',
  'Ukinami Yuzuha - Tanuki in Broad Daylight':
      'assets/characters/ukinami_yuzuha/tanuki_in_broad_daylight.png',
  'Velina Airgid - Shade of Leisure':
      'assets/characters/velina_airgid/shade_of_leisure.png',
  'Vivian - Iris of the Shore':
      'assets/characters/vivian/iris_of_the_shore.webp',
  'Wise - Soaring Crane': 'assets/characters/wise/soaring_crane.webp',
  'Wise - Peaceful Waves': 'assets/characters/wise/peaceful_waves.webp',
  'Wise - Oath of Skies': 'assets/characters/wise/oath_of_skies.webp',
  'Ye Shunguang - Touch of Dawnlight':
      'assets/characters/ye_shunguang/touch_of_dawnlight.png',
  'Yixuan - Trails of Ink': 'assets/characters/yixuan/trails_of_ink.webp',
};

const zzzAvatarAssets = <String, String>{
  'Alice Thymefield': 'assets/characters/alice_thymefield/default.png',
  'Anby Demara': 'assets/characters/anby_demara/default.png',
  'Anton Ivanov': 'assets/characters/anton_ivanov/default.png',
  'Aria': 'assets/characters/aria/default.png',
  'Astra Yao': 'assets/characters/astra_yao/default.png',
  'Asaba Harumasa': 'assets/characters/asaba_harumasa/default.png',
  'Banyue': 'assets/characters/banyue/default.png',
  'Belle': 'assets/characters/belle/default.webp',
  'Ben Bigger': 'assets/characters/ben_bigger/default.png',
  'Billy Kid': 'assets/characters/billy_kid/default.png',
  'Burnice White': 'assets/characters/burnice_white/default.png',
  'Caesar King': 'assets/characters/caesar_king/default.png',
  'Cissia': 'assets/characters/cissia/default.png',
  'Claret Flint': 'assets/characters/claret_flint/default.png',
  'Corin Wickes': 'assets/characters/corin_wickes/default.png',
  'Dialyn': 'assets/characters/dialyn/default.png',
  'Ellen Joe': 'assets/characters/ellen_joe/default.png',
  'Evelyn Chevalier': 'assets/characters/evelyn_chevalier/default.png',
  'Grace Howard': 'assets/characters/grace_howard/default.png',
  'Hugo Vlad': 'assets/characters/hugo_vlad/default.png',
  'Jane Doe': 'assets/characters/jane_doe/default.png',
  'Ju Fufu': 'assets/characters/ju_fufu/default.png',
  'Koleda Belobog': 'assets/characters/koleda_belobog/default.png',
  'Komano Manato': 'assets/characters/komano_manato/default.png',
  'Lighter': 'assets/characters/lighter/default.png',
  'Lucy': 'assets/characters/lucy/default.png',
  'Lucia': 'assets/characters/lucia/default.png',
  'Lycaon': 'assets/characters/lycaon/default.png',
  'Miyabi': 'assets/characters/miyabi/default.png',
  'Nangong Yu': 'assets/characters/nangong_yu/default.png',
  'Nekomata': 'assets/characters/nekomata/default.png',
  'Nicole Demara': 'assets/characters/nicole_demara/default.png',
  'Norma Hollowell': 'assets/characters/norma_hollowell/default.png',
  'Orphie and Magus': 'assets/characters/orphie_and_magus/default.png',
  'Pan Yinhu': 'assets/characters/pan_yinhu/default.png',
  'Phoenix Reffaella': 'assets/characters/phoenix_reffaella/default.webp',
  'Piper Wheel': 'assets/characters/piper_wheel/default.png',
  'Promeia': 'assets/characters/promeia/default.png',
  'Pulchra': 'assets/characters/pulchra/default.png',
  'Pyrois': 'assets/characters/pyrois/default.png',
  'Qingyi': 'assets/characters/qingyi/default.png',
  'Remielle Dan': 'assets/characters/remielle_dan/default.png',
  'Rina': 'assets/characters/rina/default.png',
  'Roxy Ifrita Pryce': 'assets/characters/roxy_ifrita_pryce/default.png',
  'Seed': 'assets/characters/seed/default.png',
  'Severian Lowell': 'assets/characters/severian_lowell/default.webp',
  'Seth Lowell': 'assets/characters/seth_lowell/default.png',
  'Soldier 0 - Anby': 'assets/characters/soldier_0_anby/default.png',
  'Soldier 11': 'assets/characters/soldier_11/default.png',
  'Soukaku': 'assets/characters/soukaku/default.png',
  'Sigrid de L\'Azur': 'assets/characters/sigrid_de_l_azur/default.png',
  'Starlight - Billy Kid': 'assets/characters/starlight_billy_kid/default.png',
  'Sunna': 'assets/characters/sunna/default.png',
  'Trigger': 'assets/characters/trigger/default.png',
  'Ukinami Yuzuha': 'assets/characters/ukinami_yuzuha/default.png',
  'Velina Airgid': 'assets/characters/velina_airgid/default.png',
  'Vivian': 'assets/characters/vivian/default.png',
  'Wise': 'assets/characters/wise/default.webp',
  'Yanagi': 'assets/characters/yanagi/default.png',
  'Ye Shunguang': 'assets/characters/ye_shunguang/default.png',
  'Yidhari Murphy': 'assets/characters/yidhari_murphy/default.png',
  'Yixuan': 'assets/characters/yixuan/default.png',
  'Zhao': 'assets/characters/zhao/default.png',
  'Zhu Yuan': 'assets/characters/zhu_yuan/default.png',
};
