#!/bin/bash

# 1. 실행 가능한지 확인 (워커에서 처리됨)

# 2. Docker 이미지 이름 정의
IMAGE_NAME="font-builder"

# 3. Docker 이미지 빌드
echo "Docker 이미지 빌드 중: $IMAGE_NAME..."
docker build -t $IMAGE_NAME .

# Docker 빌드 성공 여부 확인
if [ $? -ne 0 ]; then
    echo "Docker 빌드 실패. 종료합니다."
    exit 1
fi

# 4. 호스트에 출력 디렉토리 생성
OUTPUT_DIR="output_fonts"
mkdir -p $OUTPUT_DIR
echo "출력 디렉토리: $(pwd)/$OUTPUT_DIR"

# 5. sources 디렉토리의 각 .glyphs 파일 반복 처리
echo "'sources' 디렉토리의 .glyphs 파일 처리 중..."
for glyph_file in sources/*.glyphs; do
    if [ -f "$glyph_file" ]; then
        filename=$(basename "$glyph_file")
        echo "폰트 빌드 시작: $filename"

        # 6. 각 .glyphs 파일에 대해 Docker 컨테이너 실행
        # fontmake로 정적 TTF 및 OTF를 생성한 다음 Nerd Font patcher를 적용하고,
        # 패치된 TTF를 WOFF2로 변환합니다.
        docker run --rm \
            -v "$(pwd)/sources":/app/sources:ro \
            -v "$(pwd)/$OUTPUT_DIR":/app/fonts \
            -v "$(pwd)/FontPatcher":/app/FontPatcher:ro \
            $IMAGE_NAME bash -c " \
                echo 'fontmake 실행 중 ($filename): 정적 TTF 생성...' && \
                fontmake -g \"/app/sources/$filename\" -o ttf --output-dir /app/fonts && \
                echo 'fontmake 실행 중 ($filename): 정적 OTF 생성...' && \
                fontmake -g \"/app/sources/$filename\" -o otf --output-dir /app/fonts && \
                echo 'Nerd Font patcher 적용 중 (정적 TTF 및 OTF 파일)...' && \
                # 생성된 모든 TTF 및 OTF 파일을 패치합니다. font-patcher는 Nerd Font 접미사가 붙은 새 파일을 생성합니다.
                for font_file in /app/fonts/*.ttf /app/fonts/*.otf; do \
                    if [ -f \"\$font_file\" ]; then \
                        echo \"패치 중: \$font_file...\"; \
                        fontforge --script /app/FontPatcher/font-patcher --complete \"\$font_file\"; \
                    else \
                        echo \"경고: 패치할 정적 폰트 파일(\$font_file)을 찾을 수 없습니다.\"; \
                    fi \
                done && \
                echo '패치된 TTF 폰트를 WOFF2로 변환 중...' && \
                # 패치된 TTF 파일(일반적으로 -Nerd-Font.ttf로 끝남)을 WOFF2로 변환합니다.
                for patched_ttf_file in /app/fonts/*-Nerd-Font.ttf; do \
                    if [ -f \"\$patched_ttf_file\" ]; then \
                        woff2_output_file=\"\$(basename \"\$patched_ttf_file\" .ttf).woff2\"; \
                        echo \"변환 중: \$patched_ttf_file -> \$woff2_output_file...\"; \
                        fontforge -lang=py -c \"import fontforge; font = fontforge.open('\$patched_ttf_file'); font.generate('/app/fonts/\$woff2_output_file');\"; \
                    else \
                        echo \"WOFF2 변환을 위한 패치된 TTF 파일(*-Nerd-Font)을 찾을 수 없습니다.\"; \
                    fi \
                done && \
                echo '폰트 빌드, 패치 및 WOFF2 변환 완료.' \
            "
        
        if [ $? -ne 0 ]; then
            echo "폰트 빌드 또는 패치 중 오류 발생: $filename"
        else
            echo "성공적으로 폰트 빌드 및 패치 완료: $filename. 출력 위치: $OUTPUT_DIR/"
        fi
    else
        echo "sources 디렉토리에서 .glyphs 파일을 찾을 수 없습니다."
        break 
    fi
done

echo "전체 폰트 빌드 프로세스 완료."
