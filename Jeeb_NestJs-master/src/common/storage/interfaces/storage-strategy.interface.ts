export interface StorageStrategy {
  /**
   * Uploads a file to the storage provider
   * @param file The file buffer or stream
   * @param path The destination path/key (e.g., 'products/123.jpg')
   * @returns The relative path or key stored
   */
  upload(file: Express.Multer.File, path: string): Promise<string>;

  /**
   * Deletes a file from the storage provider
   * @param path The path/key to delete
   */
  delete(path: string): Promise<void>;

  /**
   * Resolves the full URL for a given path/key
   * @param path The relative path/key
   * @returns The full public URL
   */
  getUrl(path: string): string;
}
