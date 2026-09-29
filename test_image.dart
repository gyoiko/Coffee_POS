import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;

void main() async {
  final profile = await CapabilityProfile.load();
  final generator = Generator(PaperSize.mm58, profile);
  img.Image canvas = img.Image(width: 384, height: 200);
  generator.imageRaster(canvas);
  print("OK");
}
