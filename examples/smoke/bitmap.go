package main

// A small embedded 5x7 font for the exact thank-you message. CPU-generated BGRA
// texels are uploaded by guest vkCmdCopyBufferToImage, then presented by Vulkan.
// No AppKit label can cover a failed presentation.
var glyphs = map[rune][7]string{
	't': {"00100", "00100", "11111", "00100", "00100", "00100", "00011"},
	'h': {"10000", "10000", "10110", "11001", "10001", "10001", "10001"},
	'a': {"00000", "00000", "01110", "00001", "01111", "10001", "01111"},
	'n': {"00000", "00000", "10110", "11001", "10001", "10001", "10001"},
	'k': {"10000", "10000", "10010", "10100", "11000", "10100", "10010"},
	'y': {"00000", "00000", "10001", "10001", "01111", "00001", "01110"},
	'o': {"00000", "00000", "01110", "10001", "10001", "10001", "01110"},
	'u': {"00000", "00000", "10001", "10001", "10001", "10011", "01101"},
	'f': {"00110", "01001", "01000", "11100", "01000", "01000", "01000"},
	'r': {"00000", "00000", "10110", "11001", "10000", "10000", "10000"},
	'e': {"00000", "00000", "01110", "10001", "11111", "10000", "01110"},
	's': {"00000", "00000", "01111", "10000", "01110", "00001", "11110"},
	'i': {"00100", "00000", "01100", "00100", "00100", "00100", "01110"},
	'g': {"00000", "00000", "01111", "10001", "01111", "00001", "01110"},
	'!': {"00100", "00100", "00100", "00100", "00100", "00000", "00100"},
	' ': {},
}

const thankYou = "thank you for testing!"

func thankYouBitmap(width, height uint32, green bool) []byte {
	if width < uint32(len(thankYou)*6) || height < 14 {
		panic("window too small for thank-you bitmap")
	}
	pixels := make([]byte, int(width)*int(height)*4)
	background := [4]byte{230, 38, 13, 255}
	if green {
		background = [4]byte{38, 204, 13, 255}
	}
	for i := 0; i < len(pixels); i += 4 {
		copy(pixels[i:i+4], background[:])
	}
	scale := min(int(width)/(len(thankYou)*6+12), int(height)/20)
	scale = max(scale, 1)
	left := (int(width) - (len(thankYou)*6-1)*scale) / 2
	top := (int(height) - 7*scale) / 2
	for index, ch := range thankYou {
		rows, ok := glyphs[ch]
		if !ok {
			panic("missing thank-you glyph")
		}
		for y, row := range rows {
			for x, bit := range row {
				if bit != '1' {
					continue
				}
				for dy := 0; dy < scale; dy++ {
					for dx := 0; dx < scale; dx++ {
						p := ((top+y*scale+dy)*int(width) + left + (index*6+x)*scale + dx) * 4
						copy(pixels[p:p+4], []byte{255, 255, 255, 255})
					}
				}
			}
		}
	}
	return pixels
}
