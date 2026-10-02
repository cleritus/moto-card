import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../widgets/double_rule.dart';
import '../widgets/screen_header.dart';

/// §9 — the FOTO tab.
///
/// PLACEHOLDER ONLY, deliberately. Lukasz deferred photo support (upload,
/// storage, thumbnails — the API side of §9) to the very end of the project
/// on 2026-10-01. The tab exists so the five-slot bottom bar is laid out for
/// real, and it states plainly that the contact sheet is empty.
///
/// When photos do land, this screen becomes the contact sheet: 2-column
/// grid, every shot in a 6 px bone frame with a hard 4/4 shadow, a mono
/// caption strip *under* the frame (never over the image), thumbnails
/// desaturated ~0.8 via `ColorFiltered`, and the full-screen preview
/// unfiltered on clean oilBlack.
class PhotoListScreen extends StatelessWidget {
  const PhotoListScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            const ScreenHeader(
              tagLeft: 'MOTO / FOTO',
              tagRight: 'ARKUSZ STYKOWY',
              title: 'FOTO',
              subtitle: 'ODBITEK: 00',
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppGeo.screenMargin,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _EmptyFrame(),
                  const SizedBox(height: 24),
                  const DoubleRule(),
                  const SizedBox(height: 14),
                  Text('ARKUSZ STYKOWY PUSTY.', style: AppText.h1(size: 26)),
                  const SizedBox(height: 10),
                  Text(
                    'Ściana jeszcze goła. Zdjęcia dojdą na końcu projektu — '
                    'ta zakładka trzyma dla nich miejsce.',
                    style: AppText.body(color: AppColors.fadedInk),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: const BoxDecoration(
                      color: AppColors.dirtyBlack,
                      border: Border(
                        left: BorderSide(
                          color: AppColors.oxideOrange,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      'FOTO Nº 00 · FUNKCJA ODŁOŻONA · REV. 03',
                      style: AppText.data(size: 10.5, color: AppColors.fadedInk)
                          .copyWith(height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty print frame — bone border, hard shadow, mono slug where the shot
/// would be. Shows the shape the contact sheet will take.
class _EmptyFrame extends StatelessWidget {
  const _EmptyFrame();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bone,
        border: Border.all(color: const Color(0xFF9C9079)),
        boxShadow: AppGeo.shadowHard,
      ),
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              color: const Color(0xFF2E2A24),
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.fromLTRB(8, 0, 0, 7),
              child: Text(
                'BRAK ODBITKI',
                style: AppText.micro(size: 9, color: const Color(0x80E5D8B8))
                    .copyWith(letterSpacing: 9 * 0.18),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
            child: Text(
              '—.—.—— · — KM · FOTO Nº —',
              style: AppText.micro(
                size: 9.5,
                color: const Color(0xFF5E5748),
              ).copyWith(letterSpacing: 9.5 * 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
