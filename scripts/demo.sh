#!/usr/bin/env bash
set -euo pipefail

if ! command -v magick >/dev/null 2>&1; then
  echo "ImageMagick 7 is required to generate assets/demo.gif" >&2
  exit 1
fi

demo_tmp="$(mktemp -d)"
trap 'rm -rf "$demo_tmp"' EXIT

font="${SPARKS_DEMO_FONT:-}"
if [[ -z "$font" ]]; then
  for candidate in /System/Library/Fonts/Monaco.ttf /usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf; do
    if [[ -f "$candidate" ]]; then
      font="$candidate"
      break
    fi
  done
fi

font_args=()
if [[ -n "$font" ]]; then
  font_args=(-font "$font")
fi

for frame in $(seq 0 35); do
  frame_file=$(printf "%s/frame-%03d.png" "$demo_tmp" "$frame")
  args=(
    -size 960x540 xc:'#0d1117'
    -fill '#161b22' -draw 'rectangle 0,0 960,52'
    -fill '#21262d' -draw 'rectangle 0,52 68,540'
    -fill '#30363d' -draw 'rectangle 0,51 960,52'
    "${font_args[@]}"
    -fill '#e6edf3' -pointsize 20 -annotate +24+34 'sparks.nvim'
    -fill '#7d8590' -pointsize 16 -annotate +730+33 'cursor mode  |  x20'
    -fill '#484f58' -pointsize 18
    -annotate +24+102 '1' -annotate +24+138 '2' -annotate +24+174 '3'
    -annotate +24+210 '4' -annotate +24+246 '5' -annotate +24+282 '6'
    -fill '#ff7b72' -pointsize 22 -annotate +96+102 'local'
    -fill '#d2a8ff' -annotate +164+102 'sparks'
    -fill '#e6edf3' -annotate +244+102 '='
    -fill '#79c0ff' -annotate +270+102 'require'
    -fill '#a5d6ff' -annotate +365+102 '("sparks")'
    -fill '#d2a8ff' -annotate +96+150 'sparks'
    -fill '#e6edf3' -annotate +174+150 '.setup({'
    -fill '#7ee787' -annotate +132+198 'preset'
    -fill '#e6edf3' -annotate +235+198 '='
    -fill '#a5d6ff' -annotate +262+198 '"power",'
    -fill '#7ee787' -annotate +132+246 'position'
    -fill '#e6edf3' -annotate +244+246 '='
    -fill '#a5d6ff' -annotate +270+246 '"cursor",'
    -fill '#e6edf3' -annotate +96+294 '})'
    -fill '#30363d' -draw 'rectangle 0,500 960,540'
    -fill '#7ee787' -pointsize 16 -annotate +24+526 'NORMAL'
    -fill '#7d8590' -annotate +820+526 'lua  utf-8'
  )

  pulse=$((frame % 18))
  cursor_x=522
  cursor_y=232
  args+=( -fill '#f0f6fc' -draw "rectangle $cursor_x,$cursor_y $((cursor_x + 3)),$((cursor_y + 28))" )
  for index in $(seq 0 17); do
    phase=$(((pulse + index * 3) % 18))
    dx=$((((index * 37) % 121) - 60))
    dy=$((((index * 53) % 101) - 50))
    px=$((cursor_x + dx * phase / 18))
    py=$((cursor_y + 14 + dy * phase / 18 + phase * phase / 30))
    radius=$((3 - phase / 7))
    if ((radius < 1)); then radius=1; fi
    case $((index % 5)) in
      0) color='#ff7b72' ;;
      1) color='#79c0ff' ;;
      2) color='#7ee787' ;;
      3) color='#d2a8ff' ;;
      *) color='#ffa657' ;;
    esac
    args+=( -fill "$color" -draw "circle $px,$py $((px + radius)),$py" )
  done
  magick "${args[@]}" "$frame_file"
done

magick -delay 6 -loop 0 "$demo_tmp"/frame-*.png -layers Optimize assets/demo.gif
echo "Generated assets/demo.gif"
