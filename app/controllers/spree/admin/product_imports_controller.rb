class Spree::Admin::ProductImportsController < Spree::Admin::BaseController

  before_action :ensure_sample_file_exists, only: [:download_sample_csv, :sample_csv_import]
  before_action :ensure_valid_file, only: [:user_csv_import, :shopify_csv_import]
  before_action :ensure_shopify_import_file_exists, only: [:download_sample_shopify_export_csv]
  before_action :set_loader_options, only: [:sample_csv_import, :user_csv_import]

  def index
    @csv_table = CSV.open(SAMPLE_CSV_FILES[:sample_product_file], headers: true).read if File.exists? SAMPLE_CSV_FILES[:sample_product_file]
  end

  def reset
    flash[:success] = Spree::DataResetService.new.reset_products
    redirect_to admin_product_imports_path
  end

  def sample_import
  end

  def download_sample_csv
    send_file SAMPLE_CSV_FILES[:sample_product_file]
  end

  def sample_csv_import
    begin
      loader = DataShift::SpreeEcom::ProductLoader.new(nil, { verbose: true })
      loader.perform_load(SAMPLE_CSV_FILES[:sample_product_file], @options)
      flash[:success] = Spree.t(:successfull_import, resource: 'Products')
    rescue => e
      flash[:error] = e.message
    end
    redirect_to admin_product_imports_path
  end

  def user_csv_import
    begin
      loader = DataShift::SpreeEcom::ProductLoader.new(nil, { verbose: true })
      loader.perform_load(params[:csv_file].path, @options)
      flash[:success] = Spree.t(:successfull_import, resource: 'Products')
    rescue => e
      flash[:error] = e.message
    end
    redirect_to admin_product_imports_path
  end

  def download_sample_shopify_export_csv
    send_file SAMPLE_CSV_FILES[:shopify_products_export_file]
  end

  def shopify_csv_import
    begin
      transformer = DataShift::SpreeEcom::ShopifyProductTransform.new(params[:csv_file].path)
      send_data transformer.to_csv,
        type: 'text/csv; charset=iso-8859-1; header=present',
        filename: 'shopify_to_spree_mapper.csv'
    rescue => e
      flash[:error] = e.message
      redirect_to sample_import_admin_product_imports_path
    end
  end

  private
    def ensure_shopify_import_file_exists
      unless File.exists? SAMPLE_CSV_FILES[:shopify_products_export_file]
        flash[:error] = Spree.t(:sample_file_not_present)
        redirect_to admin_product_imports_path
      end
    end

    def ensure_valid_file
      unless params[:csv_file].try(:respond_to?, :path)
        flash[:error] = Spree.t(:file_invalid_error)
        redirect_to admin_product_imports_path
      end
    end

    def ensure_sample_file_exists
      unless File.exists? SAMPLE_CSV_FILES[:sample_product_file]
        flash[:error] = Spree.t(:sample_file_not_present)
        redirect_to admin_product_imports_path
      end
    end

    def set_loader_options
      @options ||= {}
      @options[:mandatory] = PRODUCT_MANDATORY_FIELDS
    end
end
