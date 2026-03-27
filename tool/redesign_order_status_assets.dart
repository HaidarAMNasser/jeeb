// Regenerates order-status PNGs: pending (no phone frame), assigned (trim margins).
// Run from project root: dart run tool/redesign_order_status_assets.dart

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

final _peach = img.ColorRgb8(255, 229, 212);
final _orange = img.ColorRgb8(226, 87, 6);

const _outSize = 512;

void main() {
  final root = Directory.current.path;
  final sep = Platform.pathSeparator;
  final dir = '$root${sep}assets${sep}images${sep}order_status';

  _writePending('$dir${sep}pending.png');
  _trimAssigned('$dir${sep}assigned.png');

  stdout.writeln('Updated: pending.png, assigned.png');
}

void _fillEllipse(
  img.Image im,
  int cx,
  int cy,
  int rx,
  int ry,
  img.ColorRgb8 color,
) {
  for (var dy = -ry; dy <= ry; dy++) {
    final t = 1 - (dy * dy) / (ry * ry);
    if (t < 0) continue;
    final px = (rx * math.sqrt(t)).round();
    img.drawLine(
      im,
      x1: cx - px,
      y1: cy + dy,
      x2: cx + px,
      y2: cy + dy,
      color: color,
      thickness: 1,
    );
  }
}

/// Bowl + steam + check — no phone frame.
void _writePending(String path) {
  final im = img.Image(width: _outSize, height: _outSize);
  img.fill(im, color: _peach);

  const cx = _outSize ~/ 2;
  const cy = _outSize ~/ 2 + 6;

  _fillEllipse(im, cx, cy + 10, 58, 32, _orange);
  _fillEllipse(im, cx, cy - 2, 40, 18, _orange);

  _wavySteam(im, cx - 26, 115, 175);
  _wavySteam(im, cx, 108, 175);
  _wavySteam(im, cx + 26, 115, 175);

  img.drawLine(
    im,
    x1: cx + 44,
    y1: cy + 8,
    x2: cx + 74,
    y2: cy - 14,
    color: _orange,
    thickness: 5,
  );

  img.drawLine(
    im,
    x1: cx - 32,
    y1: cy + 56,
    x2: cx - 8,
    y2: cy + 80,
    color: _orange,
    thickness: 6,
  );
  img.drawLine(
    im,
    x1: cx - 8,
    y1: cy + 80,
    x2: cx + 36,
    y2: cy + 42,
    color: _orange,
    thickness: 6,
  );

  File(path).writeAsBytesSync(img.encodePng(im));
}

void _wavySteam(img.Image im, int cx, int y0, int y1) {
  var x = cx;
  for (var y = y0; y < y1; y += 5) {
    final ny = (y + 5).clamp(y0, y1).toInt();
    final nx = cx + (y.isEven ? 3 : -3);
    img.drawLine(
      im,
      x1: x,
      y1: y,
      x2: nx,
      y2: ny,
      color: _orange,
      thickness: 4,
    );
    x = nx;
  }
}

/// Remove excess peach margins; pad to square then scale (no stretch).
void _trimAssigned(String path) {
  final bytes = File(path).readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    stderr.writeln('Could not decode assigned.png');
    exit(1);
  }

  final trimmed = img.trim(
    decoded,
    mode: img.TrimMode.topLeftColor,
    sides: img.Trim.all,
  );

  final tw = trimmed.width;
  final th = trimmed.height;
  final side = tw > th ? tw : th;
  final square = img.Image(width: side, height: side);
  img.fill(square, color: _peach);
  final ox = (side - tw) ~/ 2;
  final oy = (side - th) ~/ 2;
  img.compositeImage(square, trimmed, dstX: ox, dstY: oy);

  final scaled = img.copyResize(
    square,
    width: _outSize,
    height: _outSize,
    interpolation: img.Interpolation.average,
  );

  File(path).writeAsBytesSync(img.encodePng(scaled));
}
