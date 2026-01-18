extends Sprite2D

const NUMBER_WIDTH := 8
const NUMBER_HEIGHT := 16

func setup(rounds_until_castle: int) -> void:
	var digit = clampi(rounds_until_castle, 0, 9)
	texture.region = Rect2(
		Vector2(
			digit * NUMBER_WIDTH,
			0
		),
		Vector2(
			NUMBER_WIDTH,
			NUMBER_HEIGHT
		)
	)