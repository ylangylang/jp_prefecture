# coding: utf-8
require "jp_prefecture/mapping"
require "jp_prefecture/zip_mapping"

module JpPrefecture
  # 都道府県のコードと名前を扱うクラス
  class Prefecture

    attr_accessor :code, :name, :name_e, :zips

    # 配列から都道府県クラスを生成
    #
    # @example
    #   # コード/名前から都道府県クラスを生成
    #   JpPrefecture::Prefecture.build(1, '北海道', 'Hokkaido')
    #
    # @param pref [Integer] 都道府県コード
    # @param name [String] 都道府県名
    # @param name_e [String] 都道府県名(英語表記)
    # @param zips [Array] 郵便番号の配列 (array of ranges, can be used in ARel, e.g. User.where(zip: prefecture.zips))
    def self.build(code, name, name_e)
      pref = self.new

      pref.code    = code
      pref.name    = name
      pref.name_e  = name_e.capitalize
      pref.zips    = ZipMapping.data[code]

      pref
    end

    # 都道府県を検索
    #
    # @example
    #   # 都道府県コードから検索
    #   JpPrefecture::Prefecture.find(1)
    #   JpPrefecture::Prefecture.find(code: 1)
    #
    #   # 都道府県名から検索
    #   JpPrefecture::Prefecture.find(name: '北海道')
    #
    #   # 都道府県名から検索(先頭一致)
    #   JpPrefecture::Prefecture.find(name: '東京')
    #
    #   # 英語表記の都道府県名から検索
    #   JpPrefecture::Prefecture.find(name: 'Hokkaido')
    #   JpPrefecture::Prefecture.find(name: 'hokkaido')
    #
    # @param args [Integer] 都道府県コード
    # @param [Hash] args 検索条件
    # @option args [Integer] :code 都道府県コード
    # @option args [String] :name 都道府県名/英語表記の都道府県名
    # @option args [Integer] :zip 郵便番号
    # @return [JpPrefecture::Prefecture] 都道府県が見つかった場合は都道府県クラス
    # @return [nil] 都道府県が見つからない場合は nil
    def self.find(args)
      return if args.nil?

      if args.is_a?(Integer) || args.is_a?(String)
        code = args.to_i
      else
        code =
          case args.keys[0]
          when :name
            self.find_code_by_name(args[:name])
          when :code
            args[:code].to_i
          when :zip
            ZipMapping.code_for_zip(args[:zip].to_i)
          end
      end

      names = Mapping.data[code]

      return unless names

      self.build(code, names[:name], names[:name_e])
    end

    # すべての都道府県クラスを返す
    #
    # @example
    #   # 都道府県の一覧を取得
    #   JpPrefecture::Prefecture.all
    #
    #   # collection_select で選択肢を生成
    #   f.collection_select :prefecture_code, JpPrefecture::Prefecture.all, :code, :name
    #
    #   # collection_select で選択肢を生成(英語表記)
    #   f.collection_select :prefecture_code, JpPrefecture::Prefecture.all, :code, :name_e
    #
    # @return [Array] 都道府県クラスの配列
    def self.all
      Mapping.data.map do |pref|
        names = pref[1]
        self.build(pref[0], names[:name], names[:name_e])
      end
    end

  protected

    # 名前から都道府県コードを先頭一致で検索
    #
    # @param name [String] 検索する都道府県名
    # @return [Integer] 見つかった場合は都道府県コード
    # @return [nil] 見つからない場合は nil
    def self.find_code_by_name(name)
      name = name.downcase

      Mapping.data.each do |m|
        m[1].values.each do |v|
          if v.start_with?(name)
            return m[0]
          end
        end
      end

      nil
    end

  end
end
