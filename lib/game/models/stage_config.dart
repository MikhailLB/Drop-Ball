import 'package:flutter/material.dart';

class StageConfig {
  final int    number;
  final String title;
  final int    pegRows;
  final int    pegColsWide;
  final int    trapCount;
  final double movePegChance;
  final double movePegRange;
  final double minMulti;
  final double maxMulti;
  final int    goal;
  final int    lives;
  final Color  tint;
  final String orbId;

  const StageConfig({
    required this.number,
    required this.title,
    required this.pegRows,
    required this.pegColsWide,
    required this.trapCount,
    required this.movePegChance,
    required this.movePegRange,
    required this.minMulti,
    required this.maxMulti,
    required this.goal,
    required this.lives,
    required this.tint,
    required this.orbId,
  });
}

class StageBook {
  StageBook._();

  static const List<StageConfig> all = [
    StageConfig(number:1,  title:'Origin',      pegRows:8,  pegColsWide:7, trapCount:1, movePegChance:0.00, movePegRange:0,    minMulti:1.0, maxMulti:2.0,  goal:200,  lives:3, tint:Color(0xFF4FC3F7), orbId:'frost'),
    StageConfig(number:2,  title:'Dustlands',   pegRows:9,  pegColsWide:7, trapCount:1, movePegChance:0.00, movePegRange:0,    minMulti:1.0, maxMulti:3.0,  goal:350,  lives:3, tint:Color(0xFF4DB6AC), orbId:'aqua'),
    StageConfig(number:3,  title:'Canopy',      pegRows:10, pegColsWide:8, trapCount:2, movePegChance:0.00, movePegRange:0,    minMulti:1.0, maxMulti:4.0,  goal:500,  lives:3, tint:Color(0xFF81C784), orbId:'verdant'),
    StageConfig(number:4,  title:'Earthcore',   pegRows:10, pegColsWide:8, trapCount:2, movePegChance:0.10, movePegRange:12.0, minMulti:1.0, maxMulti:5.0,  goal:700,  lives:3, tint:Color(0xFFA1887F), orbId:'terra'),
    StageConfig(number:5,  title:'Cyclone',     pegRows:11, pegColsWide:9, trapCount:3, movePegChance:0.15, movePegRange:14.0, minMulti:1.0, maxMulti:6.0,  goal:1000, lives:3, tint:Color(0xFFB0BEC5), orbId:'gale'),
    StageConfig(number:6,  title:'Solaris',     pegRows:11, pegColsWide:9, trapCount:3, movePegChance:0.20, movePegRange:15.0, minMulti:1.5, maxMulti:7.0,  goal:1400, lives:3, tint:Color(0xFFFFD54F), orbId:'solar'),
    StageConfig(number:7,  title:'Inferno',     pegRows:12, pegColsWide:9, trapCount:4, movePegChance:0.25, movePegRange:16.0, minMulti:2.0, maxMulti:9.0,  goal:1800, lives:3, tint:Color(0xFFFF7043), orbId:'blaze'),
    StageConfig(number:8,  title:'Bloodtide',   pegRows:12, pegColsWide:9, trapCount:4, movePegChance:0.30, movePegRange:17.0, minMulti:2.0, maxMulti:11.0, goal:2400, lives:3, tint:Color(0xFFEF5350), orbId:'ember'),
    StageConfig(number:9,  title:'Abyss',       pegRows:12, pegColsWide:9, trapCount:5, movePegChance:0.35, movePegRange:18.0, minMulti:2.5, maxMulti:13.0, goal:3000, lives:3, tint:Color(0xFFAB47BC), orbId:'void'),
    StageConfig(number:10, title:'Apex',         pegRows:12, pegColsWide:9, trapCount:5, movePegChance:0.40, movePegRange:20.0, minMulti:3.0, maxMulti:15.0, goal:4000, lives:3, tint:Color(0xFFE040FB), orbId:'void'),
  ];

  static StageConfig at(int n) => all[(n - 1).clamp(0, all.length - 1)];
  static int get count => all.length;
}
