-- Funkin' Style (nuansa V-Slice) - skrip bawaan untuk Psych Engine EK 0.7.3 Android
-- Dimuat otomatis di semua lagu. Ubah nilai di bagian ATUR sesuai selera.

-- ===== ATUR =====
local HIDE_TIME_BAR = true     -- sembunyikan time bar
local VSLICE_SCORE = true      -- teks skor kecil "Score: 123" di bawah health bar
local VSLICE_HEALTH = false    -- paksa health bar merah-hijau (false = ikuti warna karakter)
local SPREAD_STRUMS = true     -- sebar panah pemain (hanya untuk 4 tombol)
local HIDE_OPPONENT = true     -- sembunyikan strum & note lawan
-- Hitbox biasa atau hanya panah diatur dari Options > Mobile Options > "Arrow-Only Hitbox"
local TOUCH_PAD = 25           -- (mode hanya panah) area sentuh tambahan di sekeliling panah (piksel)
-- titik tengah tiap panah (kiri, bawah, atas, kanan) sebagai pecahan lebar layar
local CENTERS = {0.134, 0.324, 0.642, 0.829}
-- ================

function onCreatePost()
	if HIDE_TIME_BAR then
		setProperty('timeBar.visible', false)
		setProperty('timeTxt.visible', false)
	end

	if VSLICE_HEALTH then
		setHealthBarColors('FF0000', '66FF33')
	end

	if VSLICE_SCORE then
		setTextSize('scoreTxt', 16)
		setTextBorder('scoreTxt', 1, '000000')
		placeScore()
	end
end

function placeScore()
	-- Di bawah health bar, sisi kanan
	local barRight = getProperty('healthBar.x') + getProperty('healthBar.width')
	setProperty('scoreTxt.x', (barRight - 140) - (screenWidth / 2))
	setProperty('scoreTxt.y', getProperty('healthBar.y') + 30)
end

function layoutStrums()
	if not SPREAD_STRUMS then return end
	if getProperty('playerStrums.length') ~= 4 then return end
	for i = 0, 3 do
		local w = getPropertyFromGroup('playerStrums', i, 'width')
		setPropertyFromGroup('playerStrums', i, 'x', (screenWidth * CENTERS[i + 1]) - (w / 2))
	end
end

-- Mode hanya panah: hilangkan efek hitbox & kecilkan area sentuh menjadi seukuran panah
function fitHitbox()
	-- Opsi mati (bawaan) = hitbox biasa, skrip tidak menyentuh hitbox sama sekali
	if not getPropertyFromClass('backend.ClientPrefs', 'data.arrowOnlyHitbox') then return end
	runHaxeCode([[
		var pad = ]] .. TOUCH_PAD .. [[;
		try {
			var hb = game._hitbox;
			if (hb != null) {
				for (i in 0...hb.array.length) {
					var b = hb.array[i];
					var s = game.playerStrums.members[i];
					if (b != null && s != null) {
						b.onDown.callback = null;
						b.onUp.callback = null;
						b.onOut.callback = null;
						b.alpha = 0;
						b.x = s.x - pad;
						b.y = s.y - pad;
						b.width = s.width + pad * 2;
						b.height = s.height + pad * 2;
					}
				}
				hb.hints.visible = false;
			}
		} catch (e:Dynamic) {
			game.addTextToDebug('Hitbox tidak bisa diatur: ' + e, 0xFFFF0000);
		}
	]])
end

-- Strum baru dibuat saat hitung mundur dimulai
function onCountdownStarted() layoutStrums() fitHitbox() end
function onSongStart() layoutStrums() fitHitbox() end

function onUpdatePost(elapsed)
	if VSLICE_SCORE then
		setTextString('scoreTxt', 'Score: ' .. (score or 0))
		placeScore()
	end

	if HIDE_OPPONENT and startedCountdown then
		for i = 0, getProperty('opponentStrums.length') - 1 do
			setPropertyFromGroup('opponentStrums', i, 'alpha', 0)
		end
	end
end
