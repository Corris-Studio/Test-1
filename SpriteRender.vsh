/*

Шейдерные версии отрисовки спрайтов с реализацией режимов смешивания, встроенных в Asphyre (fxBlend, fxAdd и т.д.).
Кроме, собственно, режима смешивания, тут влияют такие свойства, как Tiled и NoGamma, 
поэтому тут куча однотипных техник, реализующих различные комбинации этих свойств.

ТЕХНИКИ
  technique SpriteDrawSimple - не используется
  technique SpriteDraw_Test - тестовая
  technique SpriteDraw_UnknownFX
  technique SpriteDraw_None
  technique SpriteDraw_Add
  technique SpriteDraw_Blend
  technique SpriteDraw_Shadow
  technique SpriteDraw_Multiply
  technique SpriteDraw_InvMultiply
  technique SpriteDraw_BlendNA
  technique SpriteDraw_Sub
  technique SpriteDraw_RevSub
  technique SpriteDraw_Max
  technique SpriteDraw_Min
  technique SpriteDraw_AddNoAlpha
  technique SpriteDraw_ShadowedAdd - двухпроходная техника
  technique SpriteDrawSimple_NoGamma - не используется
  technique SpriteDraw_None_NoGamma
  technique SpriteDraw_Add_NoGamma
  technique SpriteDraw_Blend_NoGamma
  technique SpriteDraw_Shadow_NoGamma
  technique SpriteDraw_Multiply_NoGamma
  technique SpriteDraw_InvMultiply_NoGamma
  technique SpriteDraw_BlendNA_NoGamma
  technique SpriteDraw_Sub_NoGamma
  technique SpriteDraw_RevSub_NoGamma
  technique SpriteDraw_Max_NoGamma
  technique SpriteDraw_Min_NoGamma
  technique SpriteDraw_AddNoAlpha_NoGamma
  technique SpriteDraw_ShadowedAdd_NoGamma - двухпроходная техника
  technique SpriteDraw_None_Tiled
  technique SpriteDraw_Add_Tiled
  technique SpriteDraw_Blend_Tiled
  technique SpriteDraw_Shadow_Tiled
  technique SpriteDraw_Multiply_Tiled
  technique SpriteDraw_InvMultiply_Tiled
  technique SpriteDraw_BlendNA_Tiled
  technique SpriteDraw_Sub_Tiled
  technique SpriteDraw_RevSub_Tiled
  technique SpriteDraw_Max_Tiled
  technique SpriteDraw_Min_Tiled
  technique SpriteDraw_AddNoAlpha_Tiled
  technique SpriteDraw_ShadowedAdd_Tiled - двухпроходная техника
  technique SpriteDraw_None_Tiled_NoGamma
  technique SpriteDraw_Add_Tiled_NoGamma
  technique SpriteDraw_Blend_Tiled_NoGamma
  technique SpriteDraw_Shadow_Tiled_NoGamma
  technique SpriteDraw_Multiply_Tiled_NoGamma
  technique SpriteDraw_InvMultiply_Tiled_NoGamma
  technique SpriteDraw_BlendNA_Tiled_NoGamma
  technique SpriteDraw_Sub_Tiled_NoGamma
  technique SpriteDraw_RevSub_Tiled_NoGamma
  technique SpriteDraw_Max_Tiled_NoGamma
  technique SpriteDraw_Min_Tiled_NoGamma
  technique SpriteDraw_AddNoAlpha_Tiled_NoGamma
  technique SpriteDraw_ShadowedAdd_Tiled_NoGamma - двухпроходная техника
  technique Draw_Tail_Add - отрисовка хвостов истребителей
  technique TestTileTechnique	- Тестовая

==========================================================================================
*/


struct VS_SPRITE_IN
{
  float4 Pos: POSITION;
  float4 Col: COLOR0;
  float2 Tex: TEXCOORD0;
};

struct VS_SPRITE_OUT
{
  float4 Pos: POSITION;
  float4 Col: COLOR0;
  float2 Tex: TEXCOORD0;
};

//***************************************************************

// По-видимому, вершинный шейдер не влияет ни на что: попытки как-то повлиять на текстурные координаты или цвет - провалились. 
// Вероятно, из-за того, что эти вершины заданы сразу в пространстве экрана.
VS_SPRITE_OUT VS_SpriteColored(VS_SPRITE_IN In)
{
  VS_SPRITE_OUT Out;
  Out.Pos = In.Pos;
  Out.Col = In.Col;
  Out.Tex = In.Tex;
  return Out;
}

// Просто отрисовка изображения с учетом гаммы, помноженного на цвет вершин. 
// Если OutputGamma тут будет не равна единице, то перемножение на In.Col даст неправильный результат.
float4 PS_SpriteDrawSimple(VS_SPRITE_OUT In): COLOR
{
  return getSamplerColor(SceneTex, In.Tex, SceneTexture_Gamma, OutputGamma) * In.Col;
}
// Тестовый пиксельный шейдер. Можно использовать, подставляя в проверяемую технику, дабы убедиться, что мы работаем именно с той техникой, которая нужна.
float4 PS_SpriteDraw_Test(VS_SPRITE_OUT In): COLOR
{
  float4 resColor;
  resColor.rgb = 0.3f;
  resColor.a = 1.0f;
  return resColor;
}

// Шейдер, рисующий спрайты, у которых неизвестный режим наложения
float4 PS_SpriteDrawUnknown(VS_SPRITE_OUT In): COLOR
{
  float4 color = tex2D(SceneTex, In.Tex);
  float4 warnColor = tex2D(WarnTex, In.Tex);
  float4 resColor;
  resColor.rgb = (color.rgb + warnColor.rgb) * 0.5f;
  resColor.a = 1.0f;
  return resColor;
}

// Просто отрисовка изображения без учета гаммы, помноженного на цвет вершин. 
float4 PS_SpriteDrawSimple_NoGamma(VS_SPRITE_OUT In): COLOR
{
  // Если OutputGamma тут будет не равна единице, то перемножение на In.Col будет неправильным
  return tex2D(SceneTex, In.Tex) * In.Col;
}

float2 Tex_Left_Top = float2(0.0f, 0.0f);
float2 Tex_Right_Bottom = float2(1.0f, 1.0f);

// Возвращает текстурные координаты для тайлинга, считая "тайлом" некую зону текстуры, 
// заданную глобальными переменными Tex_Left_Top и Tex_Right_Bottom, которые могут быть изменены из внешнего кода.
// Изначально тайл равен всей текстуре.
float2 getTiledTexCoord(float2 inTex)
{
  float2 xFrac = frac(inTex);
  return lerp(Tex_Left_Top, Tex_Right_Bottom, xFrac);
}

// Просто отрисовка затайленного изображения с учетом гаммы, помноженного на цвет вершин. 
// Если OutputGamma тут будет не равна единице, то перемножение на In.Col даст неправильный результат.
float4 PS_SpriteDrawTiled(VS_SPRITE_OUT In): COLOR
{
  // Если OutputGamma тут будет не равна единице, то перемножение на In.Col будет неправильным
//  return getSamplerColor(SceneTex, In.Tex, SceneTexture_Gamma, OutputGamma) * In.Col; 
  float4 resColor = getSamplerColor(SceneTex_Tiled, getTiledTexCoord(In.Tex), SceneTexture_Gamma, OutputGamma) * In.Col; 
  /*resColor.r = Tex_Left_Top.x;
  resColor.g = Tex_Right_Bottom.x / 2.0f;
  resColor.b = 0.0f;
  resColor.a = 1.0f;*/
  return resColor;
}

// Просто отрисовка затайленного изображения без учета гаммы, помноженного на цвет вершин. 
float4 PS_SpriteDrawTiled_NoGamma(VS_SPRITE_OUT In): COLOR
{
  return tex2D(SceneTex_Tiled, getTiledTexCoord(In.Tex)) * In.Col;
}

// отрисовка хвостов истребителей
float4 PS_Draw_Tail(VS_SPRITE_OUT In): COLOR
{
  float p = SceneTexture_Gamma / OutputGamma;
  float4 inColor = pow(In.Col, p);
  return getSamplerColor(SceneTex_Tiled, In.Tex, SceneTexture_Gamma, OutputGamma) * inColor;   
}


//******************************************************************************************************************************
//********  TECHNIQUE  *********************************************************************************************************
//******************************************************************************************************************************

// не используется
technique SpriteDrawSimple
{
  pass P0
  {
    ALPHABLENDENABLE = FALSE;
    ALPHATESTENABLE = FALSE;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple();
  }
}
// Тестовая техника, просто подменяющая цвет на определенный, заданный в пиксельном шейдере.
technique SpriteDraw_Test
{
  pass P0
  {
    ALPHABLENDENABLE = FALSE;
    ALPHATESTENABLE = FALSE;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDraw_Test();
  }
}
// Техника для рисования спрайтов, у которых BlendMode неизвестен (т.е. не равен одному из определенных, вроде fxBlend, fxAdd и т.п.)
technique SpriteDraw_UnknownFX
{
  pass P0
  {
    ALPHABLENDENABLE = FALSE;
    ALPHATESTENABLE = FALSE;
    SRCBLEND = ONE;
    DESTBLEND = ZERO;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawUnknown();
  }
}
// fxNONE
technique SpriteDraw_None
{
  pass P0
  {
    ALPHABLENDENABLE = FALSE;
    ALPHATESTENABLE = FALSE;
    SRCBLEND = ONE;
    DESTBLEND = ZERO;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple();
  }
}
// fxAdd
technique SpriteDraw_Add
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = SRCALPHA;
    DESTBLEND = ONE;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple();
  }
}
// fxBlend
technique SpriteDraw_Blend
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = SRCALPHA;
    DESTBLEND = INVSRCALPHA;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple();
  }
}

// fxShadow
technique SpriteDraw_Shadow
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = ZERO;
    DESTBLEND = INVSRCALPHA;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple();
  }
}

//fxMultiply
technique SpriteDraw_Multiply
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = ZERO;
    DESTBLEND = SRCCOLOR;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple();
  }
}

//fxInvMultiply
technique SpriteDraw_InvMultiply
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = ZERO;
    DESTBLEND = INVSRCCOLOR;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple();
  }
}

//fxBlendNA
technique SpriteDraw_BlendNA
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = SRCCOLOR;
    DESTBLEND = INVSRCCOLOR;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple();
  }
}

//fxSub
technique SpriteDraw_Sub
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;   
    ALPHATESTENABLE = TRUE;    
    SRCBLEND = SRCALPHA;
    DESTBLEND = ONE;  
    BLENDOP = REVSUBTRACT; //Почему-то SUBTRACT тут дает очень странный результат, не такой, как fxSub. А REVSUBTRACT тут работает, как надо.
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple();
  }
}

//fxRevSub
technique SpriteDraw_RevSub
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = SRCALPHA;
    DESTBLEND = ONE;  
    BLENDOP = REVSUBTRACT;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple();
  }
}

//fxMax
technique SpriteDraw_Max
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = FALSE;
    SRCBLEND = ONE;
    DESTBLEND = ONE;  
    BLENDOP = MAX;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple();
  }
}

//fxMin
technique SpriteDraw_Min
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = FALSE;
    SRCBLEND = ONE;
    DESTBLEND = ONE;  
    BLENDOP = MIN;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple();
  }
}

//fxAdd без учета альфы
technique SpriteDraw_AddNoAlpha
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = FALSE;
    SRCBLEND = ONE;
    DESTBLEND = ONE;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple();
  }
}

// fxShadowedAdd - двухпроходная техника
technique SpriteDraw_ShadowedAdd
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = ZERO;
    DESTBLEND = INVSRCALPHA;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple();
  }
  pass P1
  {
    ALPHABLENDENABLE = TRUE; // поставил TRUE, так как везде ShadowedAdd уже тут с TRUE, и при рисовании планет с FALSE обнаружился косяк
    ALPHATESTENABLE = FALSE;
    SRCBLEND = ONE;
    DESTBLEND = ONE;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple();
  }
}

//********************************
// SIMPLE NO GAMMA
//********************************

// не используется
technique SpriteDrawSimple_NoGamma
{
  pass P0
  {
    ALPHABLENDENABLE = FALSE;
    ALPHATESTENABLE = FALSE;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple_NoGamma();
  }
}

// fxNONE NoGamma
technique SpriteDraw_None_NoGamma
{
  pass P0
  {
    ALPHABLENDENABLE = FALSE;
    ALPHATESTENABLE = FALSE;
    SRCBLEND = ONE;
    DESTBLEND = ZERO;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple_NoGamma();
  }
}

// fxAdd NoGamma
technique SpriteDraw_Add_NoGamma
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = SRCALPHA;
    DESTBLEND = ONE;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple_NoGamma();
  }
}

// fxBlend NoGamma
technique SpriteDraw_Blend_NoGamma
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = SRCALPHA;
    DESTBLEND = INVSRCALPHA;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple_NoGamma();
  }
}

// fxShadow NoGamma
technique SpriteDraw_Shadow_NoGamma
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = ZERO;
    DESTBLEND = INVSRCALPHA;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple_NoGamma();
  }
}

// fxMultiply NoGamma
technique SpriteDraw_Multiply_NoGamma
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = ZERO;
    DESTBLEND = SRCCOLOR;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple_NoGamma();
  }
}

// fxInvMultiply NoGamma
technique SpriteDraw_InvMultiply_NoGamma
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = ZERO;
    DESTBLEND = INVSRCCOLOR;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple_NoGamma();
  }
}

// fxBlendNA NoGamma
technique SpriteDraw_BlendNA_NoGamma
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = SRCCOLOR;
    DESTBLEND = INVSRCCOLOR;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple_NoGamma();
  }
}

// fxSub NoGamma
technique SpriteDraw_Sub_NoGamma
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = SRCALPHA;
    DESTBLEND = ONE;  
    BLENDOP = SUBTRACT;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple_NoGamma();
  }
}

// fxRevSub NoGamma
technique SpriteDraw_RevSub_NoGamma
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = SRCALPHA;
    DESTBLEND = ONE;  
    BLENDOP = REVSUBTRACT;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple_NoGamma();
  }
}

// fxMax NoGamma
technique SpriteDraw_Max_NoGamma
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = FALSE;
    SRCBLEND = ONE;
    DESTBLEND = ONE;  
    BLENDOP = MAX;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple_NoGamma();
  }
}

// fxMin NoGamma
technique SpriteDraw_Min_NoGamma
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = FALSE;
    SRCBLEND = ONE;
    DESTBLEND = ONE;  
    BLENDOP = MIN;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple_NoGamma();
  }
}

// fxAdd NoAlpha NoGamma
technique SpriteDraw_AddNoAlpha_NoGamma
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = FALSE;
    SRCBLEND = ONE;
    DESTBLEND = ONE;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple_NoGamma();
  }
}

// fxShadowedAdd NoGamma - Двухпроходная
technique SpriteDraw_ShadowedAdd_NoGamma
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = ZERO;
    DESTBLEND = INVSRCALPHA;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple_NoGamma();
  }
  pass P1
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = FALSE;
    SRCBLEND = ONE;
    DESTBLEND = ONE;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawSimple_NoGamma();
  }
}


//********************************
// TILED
//********************************
// fxNONE Tiled
technique SpriteDraw_None_Tiled
{
  pass P0
  {
    ALPHABLENDENABLE = FALSE;
    ALPHATESTENABLE = FALSE;
    SRCBLEND = ONE;
    DESTBLEND = ZERO;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawTiled();
  }
}

// fxAdd Tiled
technique SpriteDraw_Add_Tiled
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = SRCALPHA;
    DESTBLEND = ONE;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
//    PixelShader = compile ps_2_0 PS_SpriteDrawSimple();
    PixelShader = compile ps_2_0 PS_SpriteDrawTiled(); //nebulas & ships
  }
}

// fxBlend Tiled
technique SpriteDraw_Blend_Tiled
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = SRCALPHA;
    DESTBLEND = INVSRCALPHA;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawTiled(); // ship icons
  }
}

// fxShadow Tiled
technique SpriteDraw_Shadow_Tiled
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = ZERO;
    DESTBLEND = INVSRCALPHA;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawTiled();
  }
}

// fxMultiply Tiled
technique SpriteDraw_Multiply_Tiled
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = ZERO;
    DESTBLEND = SRCCOLOR;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawTiled();
  }
}

// fxInvMultiply Tiled
technique SpriteDraw_InvMultiply_Tiled
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = ZERO;
    DESTBLEND = INVSRCCOLOR;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawTiled();
  }
}

// fxBlendNA Tiled
technique SpriteDraw_BlendNA_Tiled
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = SRCCOLOR;
    DESTBLEND = INVSRCCOLOR;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawTiled();
  }
}

// fxSub Tiled
technique SpriteDraw_Sub_Tiled
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = SRCALPHA;
    DESTBLEND = ONE;  
    BLENDOP = SUBTRACT;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawTiled();
  }
}

// fxRevSub Tiled
technique SpriteDraw_RevSub_Tiled
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = SRCALPHA;
    DESTBLEND = ONE;  
    BLENDOP = REVSUBTRACT;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawTiled();
  }
}

// fxMax Tiled
technique SpriteDraw_Max_Tiled
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = FALSE;
    SRCBLEND = ONE;
    DESTBLEND = ONE;  
    BLENDOP = MAX;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawTiled();
  }
}

// fxMin Tiled
technique SpriteDraw_Min_Tiled
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = FALSE;
    SRCBLEND = ONE;
    DESTBLEND = ONE;  
    BLENDOP = MIN;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawTiled();
  }
}

// fxAdd NoAlpha Tiled
technique SpriteDraw_AddNoAlpha_Tiled
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = FALSE;
    SRCBLEND = ONE;
    DESTBLEND = ONE;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawTiled();
  }
}

// fxShadowedAdd Tiled - Двухпроходная
technique SpriteDraw_ShadowedAdd_Tiled 
{
  
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = ZERO;
    DESTBLEND = INVSRCALPHA;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawTiled(); // planet
  }
  
  pass P1
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = FALSE;
    SRCBLEND = ONE;
    DESTBLEND = ONE;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawTiled(); // planet
  }
}




//********************************
// TILED NO GAMMA
//********************************
// fxNONE Tiled NoGamma
technique SpriteDraw_None_Tiled_NoGamma
{
  pass P0
  {
    ALPHABLENDENABLE = FALSE;
    ALPHATESTENABLE = FALSE;
    SRCBLEND = ONE;
    DESTBLEND = ZERO;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawTiled_NoGamma();
  }
}

// fxAdd Tiled NoGamma
technique SpriteDraw_Add_Tiled_NoGamma
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = SRCALPHA;
    DESTBLEND = ONE;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawTiled_NoGamma();
  }
}

// fxBlend Tiled NoGamma
technique SpriteDraw_Blend_Tiled_NoGamma
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = SRCALPHA;
    DESTBLEND = INVSRCALPHA;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawTiled_NoGamma();
  }
}

// fxShadow Tiled NoGamma
technique SpriteDraw_Shadow_Tiled_NoGamma
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = ZERO;
    DESTBLEND = INVSRCALPHA;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawTiled_NoGamma();
  }
}

// fxMultiply Tiled NoGamma
technique SpriteDraw_Multiply_Tiled_NoGamma
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = ZERO;
    DESTBLEND = SRCCOLOR;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawTiled_NoGamma();
  }
}

// fxInvMultiply Tiled NoGamma
technique SpriteDraw_InvMultiply_Tiled_NoGamma
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = ZERO;
    DESTBLEND = INVSRCCOLOR;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawTiled_NoGamma();
  }
}

// fxBlendNA Tiled NoGamma
technique SpriteDraw_BlendNA_Tiled_NoGamma
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = SRCCOLOR;
    DESTBLEND = INVSRCCOLOR;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawTiled_NoGamma();
  }
}

// fxSub Tiled NoGamma
technique SpriteDraw_Sub_Tiled_NoGamma
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = SRCALPHA;
    DESTBLEND = ONE;  
    BLENDOP = SUBTRACT;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawTiled_NoGamma();
  }
}

// fxRevSub Tiled NoGamma
technique SpriteDraw_RevSub_Tiled_NoGamma
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = SRCALPHA;
    DESTBLEND = ONE;  
    BLENDOP = REVSUBTRACT;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawTiled_NoGamma();
  }
}

// fxMax Tiled NoGamma
technique SpriteDraw_Max_Tiled_NoGamma
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = FALSE;
    SRCBLEND = ONE;
    DESTBLEND = ONE;  
    BLENDOP = MAX;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawTiled_NoGamma();
  }
}

// fxMin Tiled NoGamma
technique SpriteDraw_Min_Tiled_NoGamma
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = FALSE;
    SRCBLEND = ONE;
    DESTBLEND = ONE;  
    BLENDOP = MIN;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawTiled_NoGamma();
  }
}

// fxAdd NoAlpha Tiled NoGamma
technique SpriteDraw_AddNoAlpha_Tiled_NoGamma
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = FALSE;
    SRCBLEND = ONE;
    DESTBLEND = ONE;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawTiled_NoGamma();
  }
}

// fxShadowedAdd Tiled NoGamma - Двухпроходная
technique SpriteDraw_ShadowedAdd_Tiled_NoGamma
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = ZERO;
    DESTBLEND = INVSRCALPHA;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawTiled_NoGamma();
  }
  pass P1
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = FALSE;
    SRCBLEND = ONE;
    DESTBLEND = ONE;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_SpriteDrawTiled_NoGamma();
  }
}

//**************************************************************************
// Тестовый пиксельный шейдер
float4 PS_TestTileTechnique(VS_SPRITE_OUT In): COLOR
{
  return getSamplerColor(SceneTex, getTiledTexCoord(In.Tex), SceneTexture_Gamma, OutputGamma) * In.Col;
}

// Тестовая
technique TestTileTechnique	
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = FALSE;
    SRCBLEND = SRCALPHA;
    DESTBLEND = INVSRCALPHA;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_TestTileTechnique();
  }
}

// отрисовка хвоста истребителей
technique Draw_Tail_Add
{
  pass P0
  {
    ALPHABLENDENABLE = TRUE;
    ALPHATESTENABLE = TRUE;
    SRCBLEND = SRCALPHA;
    DESTBLEND = ONE;  
    BLENDOP = ADD;
    cullmode = none;
    VertexShader = compile vs_1_1 VS_SpriteColored();
    PixelShader = compile ps_2_0 PS_Draw_Tail(); // Fighter's tail
  }
}

