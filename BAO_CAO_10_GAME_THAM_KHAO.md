# Danh Mục Hình Ảnh Thật & Phân Tích 10 Game Mã Nguồn Mở (`D:\game\references`)

> [!IMPORTANT]
> **Nguyên tắc thực hiện đã tuân thủ nghiêm ngặt:**
> - **100% ảnh và hoạt ảnh thật:** Mọi hình ảnh (`.png`, `.jpg`, `.gif`) dưới đây đều được trích xuất trực tiếp từ kho tài nguyên thật đã tải về `D:\game\references` (không dùng AI tạo ảnh, không tự vẽ icon, không trộn asset giữa các game).
> - **Tải đủ cả mã nguồn, tài nguyên Git LFS và bản chạy chính thức:** Không để kho rỗng hoặc con trỏ Git LFS.
> - **Giữ nguyên trạng `D:\game\eclipse-survivors`:** Chưa sửa code, chưa đổi engine, không đụng tới dữ liệu lưu.
> - **Bản Interactive HTML Catalog có bộ lọc & phóng to ảnh:** Mở trực tiếp tại [CATALOG_10_GAMES.html](file:///D:/game/references/CATALOG_10_GAMES.html).

---

## Tổng Quan Trạng Thái Cài Đặt & Chạy Thực Tế (10/10 Dự Án)

| # | Dự án | Thư mục (`D:\game\references\...`) | Trạng thái bản chơi Windows | Mã nguồn & Tài nguyên thật |
|---|---|---|---|---|
| **1** | **OpenDuelyst** *(Ưu tiên 1)* | [open-duelyst](file:///D:/game/references/open-duelyst) | Mã nguồn + Kho Asset gốc (chạy full game cần Firebase/Docker local) | Đã tải đủ **12,807 files** (`app/resources/units`, `fx`, `unit_gifs`, `scenes`, `sfx`) |
| **2** | **Ancient Beast** *(Ưu tiên 2)* | [ancient-beast](file:///D:/game/references/ancient-beast) | **Chạy được ngay** (Local Web Build `dist/` + `Chay Ancient Beast.bat`) | Đã tải đủ mã nguồn TypeScript/Phaser + 51 artwork, 30 cardboard, 5 đấu trường |
| **3** | **Veloren** *(Ưu tiên 3)* | [veloren](file:///D:/game/references/veloren) | **Chạy được ngay** ([veloren-voxygen.exe](file:///D:/game/references/veloren/veloren-voxygen.exe)) | Đã tải bản Windows Standalone + nguồn chính thức GitLab (`source/` + Git LFS) |
| **4** | **0 A.D.** *(Ưu tiên 4)* | [0ad](file:///D:/game/references/0ad) | **Chạy được ngay** ([pyrogenesis.exe](file:///D:/game/references/0ad/build/binaries/system/pyrogenesis.exe) + Map Editor `Atlas`) | Đã cài bản Windows 0.28.0 (`build/`, 52,829 files trong `public.zip`) + clone `source/` (38,739 files) |
| **5** | **SuperTuxKart** | [supertuxkart](file:///D:/game/references/supertuxkart) | **Chạy được ngay** ([run_game.bat](file:///D:/game/references/supertuxkart/build/SuperTuxKart-1.5-win/run_game.bat)) | Đã tải `stk-code` + bản portable 1.5 kèm trọn bộ `stk-assets` (44 đường đua, 18 xe) |
| **6** | **Mindustry** | [mindustry](file:///D:/game/references/mindustry) | **Chạy được ngay** (`Mindustry.jar` kèm Portable OpenJDK 17 JRE trong `jre/`) | Đã tải `Mindustry.jar` v160.7 + toàn bộ `source/` (`core/assets-raw/sprites/`) |
| **7** | **VoxeLibre** | [voxelibre](file:///D:/game/references/voxelibre) | **Chạy được ngay** ([luanti.exe](file:///D:/game/references/voxelibre/luanti-5.17.0-win64/bin/luanti.exe) tích hợp sẵn `mineclone2`) | Đã đồng bộ nguồn chính thức Mesehub (`git.minetest.land`) + Luanti 5.17.0 Win64 |
| **8** | **Endless Sky** | [endless-sky](file:///D:/game/references/endless-sky) | **Chạy được ngay** ([Endless Sky.exe](file:///D:/game/references/endless-sky/build/Endless%20Sky.exe)) | Đã tải bản Windows 64-bit v0.11.2 (`build/`) + toàn bộ `source/` (`data/`, `images/`) |
| **9** | **Thrive** | [thrive](file:///D:/game/references/thrive) | **Chạy được ngay** ([Thrive.exe](file:///D:/game/references/thrive/build/Thrive_1.7.0.0_windows_desktop/Thrive.exe)) | Đã tải bản Windows v1.7.0 (`build/`) + clone `source/` & pull đủ **1,214 file Git LFS thật** |
| **10** | **Xonotic** | [xonotic](file:///D:/game/references/xonotic) | **Chạy được ngay** ([xonotic.exe](file:///D:/game/references/xonotic/build/Xonotic/xonotic.exe)) | Đã tải bản Windows v0.8.6 (`build/Xonotic/`) + clone đủ 7 kho GitLab (`xonotic`, `darkplaces`, `gmqcc`, `xonotic-data.pk3dir`, `xonotic-maps.pk3dir`, `xonotic-music.pk3dir`, `netradiant`) |

---

## Phần I: Phân Tích Chuyên Sâu Nhóm Ưu Tiên 1–4

### 1. OpenDuelyst — Sinh vật Fantasy 2D, Hoạt ảnh, Kỹ năng, Hiệu ứng & Giao diện
- **Thư mục:** [D:\game\references\open-duelyst](file:///D:/game/references/open-duelyst)
- **Kho tài nguyên chính:** [app/resources](file:///D:/game/references/open-duelyst/app/resources) · **Logic SDK:** [app/sdk](file:///D:/game/references/open-duelyst/app/sdk)

````carousel
![Boss Boreal Juggernaut GIF](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/01_openduelyst_boss_boreal.gif)
<!-- slide -->
![Boss Chaos Knight GIF](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/01_openduelyst_boss_chaosknight.gif)
<!-- slide -->
![Boss Cindera GIF](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/01_openduelyst_boss_cindera.gif)
<!-- slide -->
![Magaari Ember Highlands Battlefield](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/01_openduelyst_scene_ember_highlands.jpg)
<!-- slide -->
![Obsidian Woods Battlefield](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/01_openduelyst_scene_obsidian_woods.jpg)
<!-- slide -->
![Frostfire Battlefield](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/01_openduelyst_scene_frostfire.jpg)
<!-- slide -->
![Flaming Stampede Spell FX Sheet](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/01_openduelyst_fx_flamingstampede.png)
````

- **Vòng chơi chính:** Mỗi lượt nhận thêm Mana (2 → 9), di chuyển Tướng (General) và sinh vật trên bàn cờ 9×5 ô, triệu hồi quân/phép/trang bị (Artifact), dùng quyền đổi 1 lá bài (*Replace*) mỗi lượt để lọc bộ bài, và hạ HP Tướng địch về 0.
- **Quyết định người chơi phải đưa ra:** Giành quyền kiểm soát 3 ô cầu Mana đầu trận, chọn góc đứng để kích hoạt nội tại (*Zeal* đứng cạnh Tướng, *Backstab* đâm sau lưng, *Infiltrate* bên phần sân địch, *Obelysk* triệu hồi tự động), và quyết định khi nào đổi máu Tướng lấy quyền kiểm soát bàn cờ.
- **Cách các màn khác nhau:** 6 đấu trường (`frostfire`, `magaari_ember_highlands`, `obsidian_woods`, `shimzar`, `vetruvian`) có tiền cảnh, hậu cảnh và tia sáng (*light rays*) riêng biệt; chế độ *Boss Battles* thay đổi hoàn toàn quy tắc chiến trường.
- **Cách thưởng khiến người chơi muốn tiếp tục:** Mở khóa tướng mới, hiệu ứng bài *Prismatic* lấp lánh, chế tạo thẻ bài bằng *Spirit*, và cảm giác tung chuỗi combo phép + hiệu ứng nổ nhiều lớp cực kỳ sắc nét.
- **Kiểm toán giấy phép & nguồn ([LICENSE](file:///D:/game/references/open-duelyst/LICENSE)):**
  - **Code:** **CC0 1.0 Universal** (Counterplay Games Inc. & OpenDuelyst Contributors).
  - **Ảnh & Hoạt ảnh:** **CC0 1.0 Universal** (1,392 file `units/`, 423 file `fx/`, 90 file `boss_battles/`, 128 file `scenes/`, 307 file `ui/`).
  - **Âm thanh:** **CC0 1.0 Universal** (671 file `sfx/`, 22 bản nhạc `music/`).
  - **Font chữ (Cảnh báo quan trọng):** Các font `Lato-*.ttf` và `fontawesome-webfont.*` là **SIL OFL 1.1** (dùng tự do). Tuy nhiên hai bộ font `averta-*-webfont.ttf` và `TrumpGothicPro-*.ttf` trong `app/resources/fonts/` là font thương mại bên thứ ba (CC0 mục 4c không cấp quyền sở hữu trí tuệ của bên thứ ba) -> **Tuyệt đối không dùng lại 2 font này.**

---

### 2. Ancient Beast — Thiết kế thú, Vai trò chiến đấu & Phối hợp kỹ năng
- **Thư mục:** [D:\game\references\ancient-beast](file:///D:/game/references/ancient-beast)
- **Định nghĩa thú & kỹ năng:** [src/data/units.ts](file:///D:/game/references/ancient-beast/src/data/units.ts) · **Kỹ năng từng thú:** [src/abilities](file:///D:/game/references/ancient-beast/src/abilities)

````carousel
![Chimera Artwork](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/02_ancientbeast_art_chimera.jpg)
<!-- slide -->
![Golden Wyrm Artwork](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/02_ancientbeast_art_golden_wyrm.jpg)
<!-- slide -->
![Cyber Wolf Artwork](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/02_ancientbeast_art_cyber_wolf.jpg)
<!-- slide -->
![Chimera Cardboard Unit](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/02_ancientbeast_cardboard_chimera.png)
<!-- slide -->
![Dark Forest Arena](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/02_ancientbeast_loc_dark_forest.jpg)
<!-- slide -->
![Dragon Bones Arena](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/02_ancientbeast_loc_dragon_bones.jpg)
````

- **Vòng chơi chính:** Dark Priest thu thập *Plasma* và *Energy* mỗi lượt để triệu hồi sinh vật thuộc 7 tộc Đại Tội (*Avarice, Envy, Gluttony, Lust, Pride, Sloth, Wrath*) theo bậc Level 1 → 2 → 3 trên lưới lục giác, di chuyển theo thứ tự *Initiative* và dùng bộ 4 kỹ năng riêng biệt của từng loài để hạ Dark Priest đối phương.
- **Quyết định người chơi phải đưa ra:** Đánh đổi giữa tích lũy *Plasma* để mở khóa thú bậc 3 khổng lồ (chiếm 2–3 ô lục giác) hay tiêu *Plasma* để nâng cấp kỹ năng (*Upgrade*) cho thú đang có; tính toán 9 hệ sát thương/kháng (*Pierce, Slash, Crush, Shock, Burn, Frost, Poison, Sonic, Mental*).
- **Cách các màn khác nhau:** 5 đấu trường (`Dark Forest`, `Desolated Canyon`, `Dragon Bones`, `Frozen Wall`, `Shadow Cave`) có địa hình cản đường và bẫy khác nhau trên lưới lục giác.
- **Cách thưởng khiến người chơi muốn tiếp tục:** Cơ chế **Drop Trophy** (trong [`units.ts`](file:///D:/game/references/ancient-beast/src/data/units.ts)): mỗi con thú khi chết đều rơi ra một bộ phận cơ thể đặc trưng trên ô đất; thú đồng minh hoặc địch nhặt được sẽ tăng vĩnh viễn chỉ số tương ứng trong trận.
- **Kiểm toán giấy phép & nguồn ([README.md](file:///D:/game/references/ancient-beast/README.md), [LICENSE.md](file:///D:/game/references/ancient-beast/LICENSE.md)):**
  - **Code:** **GNU AGPL v3.0** (ghi nguồn Freezing Moon / Ancient Beast).
  - **Ảnh (Artwork, Cardboards, Sprites, Locations):** **CC BY-SA 4.0** (ghi nguồn dự án Ancient Beast và họa sĩ tương ứng; tên & logo *Ancient Beast* là nhãn hiệu của Freezing Moon).
  - **Âm thanh (Music, Shouts, SFX):** **CC BY-SA 4.0**.
  - **Font chữ:** **SIL OFL 1.1** (`assets/fonts/play-v9-latin-*.woff2` — Font *Play* của Jonas Hecksher).

---

### 3. Veloren — Thế giới Fantasy, Nhiều vùng địa hình, Dungeon & Thú đồng hành
- **Thư mục:** [D:\game\references\veloren](file:///D:/game/references/veloren) · **Bản chạy:** [veloren-voxygen.exe](file:///D:/game/references/veloren/veloren-voxygen.exe)
- **Mã nguồn tạo thế giới & Dungeon:** [source/world/src](file:///D:/game/references/veloren/source/world/src) · **Sinh vật hoang dã:** [assets/common/entity/wild](file:///D:/game/references/veloren/assets/common/entity/wild)

````carousel
![Veloren Biome 1](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/03_veloren_bg1.jpg)
<!-- slide -->
![Veloren Biome 5](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/03_veloren_bg5.jpg)
<!-- slide -->
![Veloren Biome 12](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/03_veloren_bg12.jpg)
<!-- slide -->
![Veloren Biome 20](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/03_veloren_bg20.jpg)
````

- **Vòng chơi chính:** Khám phá thế giới mở nhiều quần xã bằng tàu lượn (*Glider*) và thú cưỡi, săn sinh vật hoang dã, thu thập nguyên liệu chế tạo vũ khí/giáp mô-đun, thuần hóa thú đồng hành và đánh xuống các tầng hầm ngục (*Dungeons*).
- **Quyết định người chơi phải đưa ra:** Chọn loại vũ khí quyết định bộ kỹ năng chiến đấu, ghép vật liệu chế tạo (đánh đổi tốc độ đánh, sát thương, tầm đánh, hiệu ứng chảy máu/đóng băng), quản lý *Energy/Stamina* khi lăn né và chọn cấp độ Dungeon (Tier 1 → Tier 5).
- **Cách các vùng địa hình khác nhau:** Phân vùng theo khí hậu và độ cao (Rừng rậm, Thảo nguyên, Sa mạc, Núi tuyết, Hang pha lê), mỗi vùng gắn với danh sách sinh vật riêng (`assets/common/entity/wild/*.ron`) và chủng tộc trấn giữ Dungeon riêng (*Adlet, Gnarling, Sahagin, Haniwa, Cultist, Vampire*).
- **Cách thưởng khiến người chơi muốn tiếp tục:** Vũ khí và giáp hiếm từ Boss tầng đáy Dungeon, thuần hóa thú quý hiếm làm bạn đồng hành chiến đấu/cưỡi, và khám phá thế giới mô phỏng sống động (*rtsim*).
- **Kiểm toán giấy phép & nguồn ([source/LICENSE](file:///D:/game/references/veloren/source/LICENSE), [assets/credits.ron](file:///D:/game/references/veloren/assets/credits.ron)):**
  - **Code:** **GNU GPL v3.0**.
  - **Ảnh & Voxel Models:** **GPL v3.0 / CC BY-SA 3.0 / CC BY-SA 4.0** (trừ một số model ghi chú riêng `CC-BY-NC-SA 4.0` trong `credits.ron`).
  - **Âm thanh (Cảnh báo quan trọng):** Nhiều bản nhạc trong [`assets/credits.ron`](file:///D:/game/references/veloren/assets/credits.ron) (như của *GeekyGami*) dùng **CC BY-NC-SA 4.0 kèm điều khoản không dùng cho game khác ngoài Veloren**.
  - **Font chữ:** **SIL OFL 1.1 / CC BY 4.0** (`Metamorphous`, `OpenSans`, `NotoSans`, `Sarabun`, `EnterCommand`).

---

### 4. 0 A.D. — Môi trường, Kiến trúc, Cây cối, Động vật & Bản đồ
- **Thư mục:** [D:\game\references\0ad](file:///D:/game/references/0ad) · **Bản chạy:** [pyrogenesis.exe](file:///D:/game/references/0ad/build/binaries/system/pyrogenesis.exe)
- **Mã nguồn & dữ liệu gốc:** [source/binaries/data/mods/public](file:///D:/game/references/0ad/source/binaries/data/mods/public)

````carousel
![0 A.D. Civilization Background 1](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/04_0ad_bg_1.png)
<!-- slide -->
![0 A.D. Civilization Background 2](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/04_0ad_bg_2.png)
<!-- slide -->
![0 A.D. Map Preview](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/04_0ad_map_1.png)
<!-- slide -->
![0 A.D. Hellas Random Map](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/04_0ad_hellas_map.png)
````

- **Vòng chơi chính:** Thu thập 4 loại tài nguyên (Thực phẩm, Gỗ, Đá, Kim loại) nhờ hệ thống công dân kiêm binh lính (*Citizen-Soldiers*), xây dựng công trình mở rộng biên giới lãnh thổ, nâng cấp qua 3 Thời kỳ (*Village → Town → City Phase*), lập đội hình chiến thuật và công phá trung tâm đối phương.
- **Quyết định người chơi phải đưa ra:** Điều phối tỷ lệ Citizen-Soldier giữa làm kinh tế và đi chiến đấu; chọn vị trí xây pháo đài giữ mỏ khoáng sản và hẻm núi; chọn Anh hùng (*Hero*) và nhánh công nghệ đặc trưng của từng nền văn minh.
- **Cách các màn/bản đồ khác nhau:** Hàng chục quần xã lịch sử (Địa Trung Hải, Ba Tư, Thảo nguyên, Bắc Âu, Kush, Ấn Độ) với thảm thực vật, cây cối, động vật hoang dã và địa hình sông/biển/đồi núi tác động trực tiếp tới tầm nhìn và đường hành quân.
- **Cách thưởng khiến người chơi muốn tiếp tục:** Nhìn căn cứ tiến hóa từ ngôi làng nhỏ thành Đô thị cổ đại hoành tráng với Kỳ quan (*Wonder*), mở khóa quân đoàn Tinh nhuệ (*Champions*), Voi chiến và Vũ khí công thành ở *City Phase*.
- **Kiểm toán giấy phép & nguồn (`art/LICENSE.txt`, `audio/LICENSE.txt`):**
  - **Code & Engine:** **GNU GPL v2.0+** (`license_gpl-2.0.txt`), thư viện phụ trợ **LGPL v2.1 / MIT**.
  - **Ảnh, 3D Models, Kiến trúc, Cây cối:** **CC BY-SA 3.0** — Bắt buộc ghi credit: *"Wildfire Games (http://www.wildfiregames.com/)"* kèm link CC BY-SA 3.0. Ảnh địa hình vệ tinh NASA trong `maps/random/` thuộc **Public Domain**.
  - **Âm thanh:** **CC BY-SA 3.0** (Wildfire Games Audio Team / Omri Lahav).
  - **Font chữ:** **SIL OFL 1.1 / GPL+Exception** (*Linux Libertine, Linux Biolinum, DejaVu Sans*).

---

## Phần II: Phân Tích Các Dự Án 5–10

### 5. SuperTuxKart — Bối cảnh hoạt hình 3D, Ánh sáng & Cách phối màu
- **Thư mục:** [D:\game\references\supertuxkart](file:///D:/game/references/supertuxkart) · **Bản chạy:** [run_game.bat](file:///D:/game/references/supertuxkart/build/SuperTuxKart-1.5-win/run_game.bat) · **Kho Asset:** [stk-assets](file:///D:/game/references/supertuxkart/stk-assets)

````carousel
![Black Forest Track](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/05_stk_black_forest.jpg)
<!-- slide -->
![Fort Magma Track](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/05_stk_fortmagma.jpg)
<!-- slide -->
![Abyss Track](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/05_stk_abyss.jpg)
<!-- slide -->
![Snow Tux Peak Track](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/05_stk_snowtuxpeak.jpg)
````

- **Vòng chơi chính:** Chọn nhân vật/xe theo hạng cân, đua qua đường đua 3D nhiều nhánh, ôm cua *Drift (Skid)* tích lũy tăng tốc, nhặt bình *Nitro* và hộp vật phẩm tấn công/phòng thủ.
- **Quyết định người chơi phải đưa ra:** Chọn đường đi ăn Nitro hay ăn Item Box; giữ vật phẩm làm khiên chắn hay tấn công ngay; xả Nitro ở đoạn dốc hay đường tắt.
- **Cách các màn khác nhau:** 44 đường đua trong `stk-assets/tracks/` mỗi màn có bảng màu ánh sáng IBL, sương mù và chướng ngại vật động riêng (Rừng thu *Black Forest*, Dung nham *Fort Magma*, Đáy đại dương *Abyss*, Đền *Cocoa Temple*).
- **Cách thưởng khiến người chơi muốn tiếp tục:** Mở khóa khu vực mới trong *Story Mode Overworld*, mở khóa nhân vật/xe mới và cúp *Grand Prix*.
- **Giấy phép:**
  - **Code:** **GNU GPL v3.0+** ([stk-code/COPYING](file:///D:/game/references/supertuxkart/stk-code/COPYING)).
  - **Ảnh / 3D Assets / Âm thanh:** **CC BY-SA 3.0 / CC BY-SA 4.0 / CC BY 3.0 / GPL v3 / Public Domain** (ghi cụ thể từng màn trong `tracks/*/licenses.txt`).
  - **Font chữ:** **SIL OFL 1.1** (*SigmarOne, Cantarell, Noto*) & **GPLv3+Exception / Apache 2.0** (*wqy-microhei*) trong [stk-assets/ttf/LICENSE](file:///D:/game/references/supertuxkart/stk-assets/ttf/LICENSE).

---

### 6. Mindustry — Tiến trình mở khóa, Tài nguyên, Cây nghiên cứu, Bản đồ & Đợt địch
- **Thư mục:** [D:\game\references\mindustry](file:///D:/game/references/mindustry) · **Bản chạy:** `Mindustry.jar` (chạy bằng `jre\jdk-17.*\bin\java.exe -jar Mindustry.jar`)
- **Cây nghiên cứu & Hành tinh:** [Planets.java](file:///D:/game/references/mindustry/source/core/src/mindustry/content/Planets.java) · [SectorPresets.java](file:///D:/game/references/mindustry/source/core/src/mindustry/content/SectorPresets.java) · [TechTree.java](file:///D:/game/references/mindustry/source/core/src/mindustry/content/TechTree.java)

````carousel
![Foreshadow Turret](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/06_mindustry_turret_foreshadow.png)
<!-- slide -->
![Breach Turret](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/06_mindustry_turret_breach.png)
<!-- slide -->
![Arc Turret](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/06_mindustry_turret_arc.png)
<!-- slide -->
![Mindustry Unit Sprite](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/06_mindustry_unit_1.png)
````

- **Vòng chơi chính:** Đáp Core xuống Sector, khai thác quặng, xây dây chuyền luyện kim/điện năng, cấp đạn cho tháp pháo và xưởng quân đội để trụ vững qua các đợt sóng địch (*Waves*) hoặc đánh sập căn cứ địch.
- **Quyết định người chơi phải đưa ra:** Đưa tài nguyên về Core để mở khóa *Tech Tree* hay dồn ra tiền tuyến làm đạn phòng thủ; thiết kế dây chuyền không bị tắc nghẽn; chọn Sector tiếp theo để chinh phục trên bản đồ hành tinh.
- **Cách các màn khác nhau:** 2 hành tinh (*Serpulo* và *Erekir*) có bộ công nghệ và luật chơi riêng biệt; mỗi Sector có phân bố quặng, địa hình nút thắt và chủng loại đợt địch (quái bộ, quái bay, quái nhện vượt tường, Boss Guardian) khác nhau.
- **Cách thưởng khiến người chơi muốn tiếp tục:** Mỗi loại khoáng sản mới khai thác được mở khóa ngay một nhánh công nghệ tháp pháo và robot khổng lồ trong `TechTree.java`, cộng thêm khả năng xuất khẩu tài nguyên liên vùng bằng bệ phóng (*Launch Pad*).
- **Giấy phép ([source/LICENSE](file:///D:/game/references/mindustry/source/LICENSE)):**
  - **Code:** **GNU GPL v3.0** (Anuke).
  - **Ảnh & Âm thanh:** **CC BY-SA 4.0 / GPL v3.0** (Anuke).
  - **Font chữ:** **SIL OFL 1.1 / GPL v3.0** (`core/assets/fonts/`).

---

### 7. VoxeLibre — Quần xã, Sinh vật, Vật phẩm, Chế tạo & Khám phá
- **Thư mục:** [D:\game\references\voxelibre](file:///D:/game/references/voxelibre) · **Bản chạy:** [luanti.exe](file:///D:/game/references/voxelibre/luanti-5.17.0-win64/bin/luanti.exe)
- **Mã nguồn Quần xã & Sinh vật:** [mcl_biomes/init.lua](file:///D:/game/references/voxelibre/source/mods/MAPGEN/mcl_biomes/init.lua) · [mobs_mc](file:///D:/game/references/voxelibre/source/mods/ENTITIES/mobs_mc)

````carousel
![VoxeLibre Biome 1](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/07_voxelibre_bg1.png)
<!-- slide -->
![VoxeLibre Biome 4](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/07_voxelibre_bg4.png)
<!-- slide -->
![VoxeLibre Biome 8](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/07_voxelibre_bg8.png)
````

- **Vòng chơi chính:** Thu thập tài nguyên, chế tạo công cụ/giáp theo bậc khoáng sản, xây dựng căn cứ, trồng trọt duy trì thanh đói, đào mỏ sâu, phù phép (*Enchanting*) và thám hiểm chiều không gian *Nether / The End*.
- **Quyết định người chơi phải đưa ra:** Quản lý độ bền trang bị, ô chứa đồ và lương thực khi đi xa; chọn thuộc tính phù phép và thuốc giả kim trước khi đánh Boss.
- **Cách các quần xã khác nhau:** Hệ thống `mcl_biomes` định nghĩa hàng chục quần xã theo nhiệt độ, độ ẩm, độ cao kèm bảng màu bầu trời, sương mù và mặt nước riêng biệt.
- **Cách thưởng khiến người chơi muốn tiếp tục:** Phát hiện công trình ẩn (Đền thờ, Ngôi làng, Pháo đài), rương kho báu, khuôn trang trí giáp (*Armor Trims*) và mạch tự động hóa *Redstone*.
- **Giấy phép ([LEGAL.md](file:///D:/game/references/voxelibre/source/LEGAL.md), [CREDITS.md](file:///D:/game/references/voxelibre/source/CREDITS.md)):**
  - **Code:** **GNU GPL v3.0+**.
  - **Ảnh & Âm thanh:** **CC BY-SA 3.0 / CC BY-SA 4.0 / CC BY 4.0 / CC0** (ảnh nền `menu/background.*.png` là **CC0**; bộ texture chính dựa trên *Pixel Perfection* của XSSheep).
  - **Font chữ:** **Apache 2.0 / SIL OFL 1.1** (đi kèm Luanti Engine).

---

### 8. Endless Sky — Nhiệm vụ, Phe phái, Trang bị, Khám phá & Đội hình hộ tống
- **Thư mục:** [D:\game\references\endless-sky](file:///D:/game/references/endless-sky) · **Bản chạy:** [Endless Sky.exe](file:///D:/game/references/endless-sky/build/Endless%20Sky.exe)
- **Dữ liệu phe phái & trang bị:** [source/data](file:///D:/game/references/endless-sky/source/data) · **Hình ảnh:** [source/images](file:///D:/game/references/endless-sky/source/images)

````carousel
![Endless Sky Asteroid Scene](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/08_endlesssky_scene_asteroid.jpg)
<!-- slide -->
![Endless Sky City Scene](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/08_endlesssky_scene_citydark.jpg)
<!-- slide -->
![Endless Sky Ship 1](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/08_endlesssky_ship_1.png)
<!-- slide -->
![Endless Sky Ship 3](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/08_endlesssky_ship_3.png)
````

- **Vòng chơi chính:** Nhận nhiệm vụ vận chuyển/hộ tống/săn tiền thưởng giữa các hệ sao, dùng tiền nâng cấp trang bị (*Outfits*) cho tàu chính, mua hoặc bắt giữ tàu địch để xây dựng **Đội hình hộ tống (Escort Fleet)** và khám phá cốt truyện của 19 chủng tộc.
- **Quyết định người chơi phải đưa ra:** Cân bằng không gian lắp đặt (*Outfit Space*), công suất vũ khí/động cơ, năng lượng và **tản nhiệt (Heat Dissipation)**; điều phối vai trò các tàu hộ tống trong hạm đội.
- **Cách các vùng không gian khác nhau:** 19 phe phái (`human`, `hai`, `remnant`, `wanderer`, `korath`, `coalition`, `quarg`...) có hệ sinh thái tàu, vũ khí và phương thức du hành không gian riêng.
- **Cách thưởng khiến người chơi muốn tiếp tục:** Cơ chế **đánh tê liệt và bắt giữ (Board & Capture) tàu địch** ngay trên chiến trường để biến tàu địch thành tàu hộ tống của mình, cùng việc mở khóa công nghệ người ngoài hành tinh.
- **Giấy phép ([source/copyright](file:///D:/game/references/endless-sky/source/copyright)):**
  - **Code & Data:** **GNU GPL v3.0+**.
  - **Ảnh:** Ảnh phong cảnh `images/land/*` và `images/scene/*` đa số là **Public Domain / CC0**; ảnh tàu và trang bị `images/ship/*`, `images/outfit/*` là **CC BY-SA 4.0 / CC BY-SA 3.0 / CC BY 3.0**.
  - **Âm thanh:** **CC0 / CC BY 3.0 / CC BY-SA 3.0 / GPLv3**.
  - **Font chữ:** **Ubuntu Font License 1.0** (`images/font/ubuntu*.png`).

---

### 9. Thrive — Tiến hóa sinh vật, Tùy biến cơ thể & Môi trường sống
- **Thư mục:** [D:\game\references\thrive](file:///D:/game/references/thrive) · **Bản chạy:** [Thrive.exe](file:///D:/game/references/thrive/build/Thrive_1.7.0.0_windows_desktop/Thrive.exe)
- **Thông số tiến hóa & môi trường:** [simulation_parameters/microbe_stage](file:///D:/game/references/thrive/source/simulation_parameters/microbe_stage)

````carousel
![Thrive Hydrothermal Vents](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/09_thrive_hydrothermal_vents.png)
<!-- slide -->
![Thrive Epipelagic Zone](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/09_thrive_epipelagic.png)
<!-- slide -->
![Thrive Tidepool](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/09_thrive_tidepool.png)
<!-- slide -->
![Thrive Estuary](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/09_thrive_estuary.png)
````

- **Vòng chơi chính:** Bơi thu thập hợp chất sinh học (Glucose, Ammonia, Phosphate), chiến đấu hoặc chạy trốn các loài cạnh tranh, tích đủ chất để sinh sản và vào **Trình chỉnh sửa cơ thể (Organelle Editor)** dùng 100 điểm Đột biến (*Mutation Points*) gắn thêm bào quan/vũ khí sinh học.
- **Quyết định người chơi phải đưa ra:** Thiết kế hình dáng và cấu trúc tế bào (cân bằng giữa sản xuất năng lượng ATP và chi phí vận động *Osmoregulation*), chọn vũ khí sinh học (độc tố *Oxytoxy*, gai đâm *Pilus*, màng nuốt chửng *Engulfment*) và chọn di cư sang vùng môi trường (*Patch*) nào.
- **Cách các môi trường sống khác nhau:** Mỗi *Biome Patch* ([biomes.json](file:///D:/game/references/thrive/source/simulation_parameters/microbe_stage/biomes.json)) có tỷ lệ ánh sáng mặt trời, oxy, lưu huỳnh, dòng chảy và quần thể loài săn mồi (do thuật toán *Auto-Evo* tự tiến hóa mỗi thế hệ) khác hẳn nhau.
- **Cách thưởng khiến người chơi muốn tiếp tục:** Nhìn sinh vật tự tay thiết kế thích nghi, thống trị bảng dân số sinh thái và tiến hóa từ đơn bào lên đa bào (*Multicellular Stage*).
- **Giấy phép ([source/LICENSE.txt](file:///D:/game/references/thrive/source/LICENSE.txt), [source/assets/LICENSE.txt](file:///D:/game/references/thrive/source/assets/LICENSE.txt)):**
  - **Code:** **GNU GPL v3.0+ kèm Mod Linking Exception**.
  - **Ảnh & Âm thanh:** **CC BY-SA 3.0 Unported** (đã pull đầy đủ 1,214 file Git LFS thật).
  - **Font chữ:** **SIL OFL 1.1** (*Jura, Lato, NotoSans, RobotoMono, thrive.ttf*).

---

### 10. Xonotic — Phản hồi chiến đấu, Đạn, Hiệu ứng nổ, Âm thanh & Thiết kế đấu trường
- **Thư mục:** [D:\game\references\xonotic](file:///D:/game/references/xonotic) · **Bản chạy:** [xonotic.exe](file:///D:/game/references/xonotic/build/Xonotic/xonotic.exe)
- **Cấu hình cân bằng đạn & hiệu ứng nổ:** [bal-wep-xonotic.cfg](file:///D:/game/references/xonotic/source/data/xonotic-data.pk3dir/bal-wep-xonotic.cfg) · [effectinfo.txt](file:///D:/game/references/xonotic/source/data/xonotic-data.pk3dir/effectinfo.txt)

````carousel
![Xonotic Afterslime Arena](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/10_xonotic_map_2_afterslime.jpg)
<!-- slide -->
![Xonotic Atelier Arena](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/10_xonotic_map_3_atelier.jpg)
<!-- slide -->
![Xonotic Boil Arena](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/10_xonotic_map_4_boil.jpg)
<!-- slide -->
![Xonotic HUD & Weapons](/C:/Users/truon/.gemini/antigravity/brain/8d948b89-2c5d-4f23-be37-123ec5a6278f/catalog_assets/10_xonotic_map_1__hudsetup.jpg)
````

- **Vòng chơi chính:** Di chuyển gia tốc cao trong đấu trường 3D nhiều tầng, kiểm soát vị trí hồi Vũ khí/Giáp/Máu lớn, và kết hợp 9 loại vũ khí (mỗi súng có 2 chế độ bắn *Primary + Secondary*) để tiêu diệt đối thủ.
- **Quyết định người chơi phải đưa ra:** Phối hợp chuyển đổi vũ khí tức thời (*Combo Switching*: bắn quả cầu điện *Electro* phụ rồi bắn tia chính kích nổ lan; dùng lực đẩy lùi *Knockback Force* của *Mortar/Devastator* hất địch xuống vực hoặc tự đẩy mình bay qua bản đồ).
- **Cách các đấu trường khác nhau:** Hơn 30 đấu trường có cấu trúc trục dọc (Verticality), bệ phóng (*Jump Pads*), cổng dịch chuyển (*Teleporters*), nguy hiểm môi trường (dung nham, axit, hố không gian) và chế độ chơi khác nhau.
- **Cách thưởng khiến người chơi muốn tiếp tục:** **Phản hồi chiến đấu (Combat Feedback / Juice)** cực kỳ thỏa mãn: âm báo trúng đạn đổi cao độ theo sát thương (*Pitch-scaled Hit-sound*), vệt đạn sáng rõ, vụ nổ 4 lớp hạt (`effectinfo.txt`) và lực đẩy vật lý tức thời.
- **Giấy phép ([COPYING](file:///D:/game/references/xonotic/source/COPYING)):**
  - **Code:** **GNU GPL v3.0+** (QuakeC game code) & **GNU GPL v2.0+** (DarkPlaces Engine).
  - **Ảnh, Models, Particles, Maps & Âm thanh:** **GNU GPL v3.0+ / GPL v2.0+**.
  - **Font chữ:** **GPL v2.0+ with Font Exception / SIL OFL 1.1** (*Xolonium* & *GNU Unifont*).

---

## Phần III: Đúc Kết Bài Học Áp Dụng Cho `eclipse-survivors` (Chưa Sửa Code Hiện Tại)

1. **Cách làm hình ảnh nhân vật, quái & hiệu ứng phép đồng bộ (Học từ OpenDuelyst + SuperTuxKart):**
   - Tách rõ **Độ tương phản nền vs Nhân vật/Đạn**: Nền màn chơi dùng độ bão hòa vừa phải và phân vùng sáng-tối theo khu vực (như `OpenDuelyst/app/resources/scenes/`), còn nhân vật, quái và đạn/phép dùng viền sáng sắc nét và hiệu ứng tách lớp (`app/resources/fx/`).
   - Nếu chọn hướng **2D Dark/High Fantasy có sẵn tài nguyên CC0**, kho **OpenDuelyst** (`1,392 unit files + 423 FX files`, giấy phép **CC0 1.0**) là nguồn đồng bộ nhất (chỉ cần giữ nguyên một phong cách pixel-art của OpenDuelyst, không trộn lẫn với game khác, và bỏ qua 2 font thương mại `Averta`/`TrumpGothicPro`).
2. **Cách thiết kế vai trò quái thú, kháng nguyên tố & phần thưởng rơi tại chỗ (Học từ Ancient Beast + Thrive):**
   - Thay vì quái chỉ khác nhau về lượng máu, học cấu trúc [`src/data/units.ts`](file:///D:/game/references/ancient-beast/src/data/units.ts) của **Ancient Beast**: phân chia quái theo Vai trò (Tank chắn đường, Cấu rỉa tầm xa, Đặt bẫy vùng, Hồi phục/Buff đồng minh) và cơ chế **Drop Trophy** (hạ quái tinh nhuệ rơi ra vật phẩm cường hóa đặc trưng ngay tại vị trí chết, buộc người chơi phải quyết định có lao vào đám đông để nhặt hay không).
3. **Cách làm các màn chơi / vùng đất khác biệt thực sự (Học từ Veloren + 0 A.D. + VoxeLibre):**
   - Mỗi màn chơi (Stage/Biome) không chỉ đổi màu gạch nền mà cần thay đổi cả 3 lớp: **(1) Bảng màu khí quyển & ánh sáng viền**, **(2) Vật cản/Điểm nhấn kiến trúc (Landmarks)**, và **(3) Quần thể sinh vật + Điều kiện môi trường riêng** (như *Hydrothermal Vents* vs *Tidepool* trong Thrive hay 6 đấu trường trong OpenDuelyst).
4. **Cách làm cảm giác bắn/đánh "đã tay" và nhịp độ đợt địch (Học từ Xonotic + Mindustry + Endless Sky):**
   - **Phản hồi va chạm 4 lớp (Xonotic `effectinfo.txt`):** Chớp sáng 1 frame tại tâm va chạm + hạt văng theo hướng đạn + vòng sóng xung kích (Shockwave) + âm thanh báo trúng đổi cao độ theo sát thương kèm lực đẩy lùi (*Knockback Force*).
   - **Đội hình hộ tống / Thú đi theo (Endless Sky + Veloren):** Cho phép người chơi thu phục thú đồng hành đi theo đội hình quanh nhân vật với lệnh hành vi đơn giản (Tập trung hỏa lực / Bảo vệ vòng trong / Tự do săn đuổi).
