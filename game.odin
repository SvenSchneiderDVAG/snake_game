package snake

import rl "vendor:raylib"
import "core:fmt"

WINDOW_SIZE :: 1000
GRID_WIDTH :: 20
CELL_SIZE :: 16
CANVAS_SIZE :: GRID_WIDTH * CELL_SIZE // zoom in camera
TICK_RATE :: 0.13
Vec2i :: [2]int
MAX_SNAKE_LENGTH :: GRID_WIDTH * GRID_WIDTH

snake: [MAX_SNAKE_LENGTH]Vec2i
snake_length: int
tick_timer: f32 = TICK_RATE // first tick will long 0.13 seconds
move_direction: Vec2i
game_over: bool
score: int
high_score: int
food_pos: Vec2i

place_food :: proc() {
	occupied: [GRID_WIDTH][GRID_WIDTH]bool

	for i in 0 ..< snake_length {
		occupied[snake[i].x][snake[i].y] = true
	}

	free_cells := make([dynamic]Vec2i, context.temp_allocator)

	for x in 0 ..< GRID_WIDTH {
		for y in 0 ..< GRID_WIDTH {
			if !occupied[x][y] {
				append(&free_cells, Vec2i{x, y})
			}
		}
	}

	if len(free_cells) > 0 {
		ranom_cell_index := rl.GetRandomValue(0, i32(len(free_cells) - 1))
		food_pos = free_cells[ranom_cell_index]
	}
}

restart :: proc() {
	start_head_pos := Vec2i{GRID_WIDTH / 2, GRID_WIDTH / 2}
	snake[0] = start_head_pos
	snake[1] = start_head_pos - {0, 1}
	snake[2] = start_head_pos - {0, 2}
	snake_length = 3
	move_direction = {0, 1}
	tick_timer = TICK_RATE
	game_over = false
	place_food()
	if score > high_score {
		high_score = score
	}
}

calculate_score :: proc() {
	score = snake_length - 3
}

display_score :: proc() {
	score_str := fmt.ctprintf("Score: %v", score)
	high_score_str := fmt.ctprintf("High Score: %v", high_score)

	rl.DrawText(score_str     , 4  , CANVAS_SIZE - 14, 10, rl.WHITE)
	rl.DrawText(high_score_str, 250, CANVAS_SIZE - 14, 10, rl.YELLOW)
}

main :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.SetTargetFPS(500)
	rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, "Snake")
	defer rl.CloseWindow()

	restart()

	for !rl.WindowShouldClose() {
		if rl.IsKeyDown(.UP)    { move_direction = {0, -1} }
		if rl.IsKeyDown(.DOWN)  { move_direction = {0, 1} }
		if rl.IsKeyDown(.LEFT)  { move_direction = {-1, 0} }
		if rl.IsKeyDown(.RIGHT) { move_direction = {1, 0} }

		if game_over {
			if rl.IsKeyPressed(.ENTER) {
				restart()
			}
		} else {
			tick_timer -= rl.GetFrameTime()
		}

		if tick_timer <= 0 {
			next_part_pos := snake[0]
			snake[0] += move_direction
			head_pos := snake[0]

			// if snake hits the wall
			if head_pos.x < 0 ||
			   head_pos.x >= GRID_WIDTH ||
			   head_pos.y < 0 ||
			   head_pos.y >= GRID_WIDTH {
				game_over = true
			}

			for i in 1 ..< snake_length {
				cur_pos := snake[i]

				// if snake hits itself
				if cur_pos == head_pos {
					game_over = true
				}

				snake[i] = next_part_pos
				next_part_pos = cur_pos
			}

			if head_pos == food_pos {
				snake_length += 1
				if snake_length < MAX_SNAKE_LENGTH {
					snake[snake_length - 1] = next_part_pos
					place_food()
				}
			}

			tick_timer = TICK_RATE + tick_timer // you could lose some time so we add the tick_timer
		}

		rl.BeginDrawing()
		defer rl.EndDrawing()

		rl.ClearBackground({76, 53, 83, 255})

		camera := rl.Camera2D {
			zoom = f32(WINDOW_SIZE / CANVAS_SIZE),
		}

		rl.BeginMode2D(camera)

		food_rect := rl.Rectangle {
			f32(food_pos.x) * CELL_SIZE,
			f32(food_pos.y) * CELL_SIZE,
			CELL_SIZE,
			CELL_SIZE,
		}

		rl.DrawRectangleRec(food_rect, rl.RED)

		for i in 0 ..< snake_length {
			head_rect := rl.Rectangle {
				f32(snake[i].x) * CELL_SIZE,
				f32(snake[i].y) * CELL_SIZE,
				CELL_SIZE,
				CELL_SIZE,
			}

			rl.DrawRectangleRec(head_rect, rl.WHITE)
		}

		calculate_score()
		display_score()

		if game_over {
			rl.DrawText("Game Over", 4, 4, 25, rl.RED)
			rl.DrawText("Press Enter to restart", 4, 30, 15, rl.WHITE)
		}

		rl.EndMode2D()
		free_all(context.temp_allocator)
	}
}
